function [card_est,resp_est,temporal_c,temporal_r]=apply_PESTICA(comps,ep2d_filename,mask_filename,Ptemplate)
%function apply_PESTICA(comps,ep2d_filename,mask_filename,slice_timing)
% requires number of components used in ICA decomposision, filename for
% EPI data, and optional parameters for a mask filename and the slice_timing
% which must be a vector of length == number of slices in data/decomposition
% which specifies relative timing (0 to 1) of the slices as indexed
% so for a typical sequential sequence with 30 slices, use slice_timing=linspace(0,1-1/30,30)
% however, you can use the strings 'seq' or 'alt' for sequential or interleaved
% and add the strings 'des' or 'asc' for descending or ascending, with a '-'
% between them such as 'seq-des', 'alt-asc', 'seq-asc', 'alt-des'
% TE is also optional and only relevant for manually specified or siemens slice_timing
%
% 1. applies the transformed PESTICA averaged maps to the independent components
%    spatial maps to find the components most likely to be physiologic noise
% 2. variance-normalizes, detrends, re-orders, and interpolates the independent
%    components according to the slice_timing
% 3. SMS acquisition is considered
%
% Note: Siemens product ep2d_pace sequence has 20ms pause at end of every volume, even if
% PACE is turned off, this slice_timing can be activated using 'siemens' for the slice_timing
% of an interleaved ascending sequence.  Otherwise, specify your own in fractions from 0 to 1
%
% use accompanying script tfilter_fft for FFT frequency filtering:
% plot(linspace(0,1,length(card_est)),abs(fft(card_est)));
%    then visually look for the cardiac peak, and select percentages surrounding it

[err, ainfo]=BrikInfo(ep2d_filename);
xdim=ainfo.DATASET_DIMENSIONS(1);
ydim=ainfo.DATASET_DIMENSIONS(2);
zdim=ainfo.DATASET_DIMENSIONS(3);
tdim=ainfo.DATASET_RANK(2);
TR=double(ainfo.TAXIS_FLOATS(2));          % ms
[TRsec TRms] = TRtimeunitcheck(TR);

slice_timing_sec=load('tshiftfile.1D');
% check SMS acquisition
[MBacc zmbdim uniq_slice_timing_sec uniq_acq_order] = SMSacqcheck(TRsec, zdim, slice_timing_sec);

% open the averaged spatial unmixing matrices
if ~exist('Ptemplate')
  Ptemplate='PESTICA5';
end

% read pestica templates
if exist(['resp_' Ptemplate '.nii'])
  card = niftiread(['card_' Ptemplate '.nii']);
  resp = niftiread(['resp_' Ptemplate '.nii']);
elseif exist(['resp_' Ptemplate '.nii.gz'])
  card = niftiread(['card_' Ptemplate '.nii.gz']);
  resp = niftiread(['resp_' Ptemplate '.nii.gz']);
else 
  disp('ERROR')
  return
end

% define mask for card. and resp.
mask_resp=int16(zeros(xdim,ydim,zdim));
mask_resp(find(resp~=0))=1;
mask_card=int16(zeros(xdim,ydim,zdim));
mask_card(find(card~=0))=1;

% read mask
if (exist('mask_filename','var')==1)
  Opt.Format = 'matrix';
  [err,mask,minfo,ErrMessage]=BrikLoad(mask_filename, Opt);
  mask = mask(:,:,:,1);
  mask=int16(mask).*mask_card.*mask_resp;
  mask(find(mask~=0))=1;
else
  disp('brain file does not exist, using template alone for mask');
  mask=mask_card.*mask_resp;
end

[w,zstart]=system(sprintf('ls pestica5_%dcomps_slice*.mat | sed "s/pestica5_%dcomps_slice//" | sed "s/.mat//" | sort -n',comps,comps));
zstart=[str2num(zstart)'];
sdim_slices=zeros(zdim,1);
load(sprintf('pestica5_%dcomps_slice%d.mat',comps,zstart(1)),'A');
tdim_ica=size(A,2);
if (tdim_ica<tdim)
  disp('discarded volumes at beginning of scan, correcting tdim to account for these...');
  tdim_skip=tdim-tdim_ica;
  tdim=tdim_ica;
end

slice_timeseries=zeros(zdim,comps,tdim);
comp_r=zeros(zdim,1);     comp_c=zeros(zdim,1);
max_comp_r=zeros(zdim,1); max_comp_c=zeros(zdim,1);

for z=1:zdim
  if exist(sprintf('pestica5_%dcomps_slice%d.mat',comps,z))
    load(sprintf('pestica5_%dcomps_slice%d.mat',comps,z));
    
    clear D;
    q=0;
    clear sparsed_m sparsed_resp sparsed_card;
    sl_mask=reshape(mask(:,:,z),[xdim*ydim 1]);
    sl_resp=reshape(resp(:,:,z),[xdim*ydim 1]);
    sl_card=reshape(card(:,:,z),[xdim*ydim 1]);
    indices=find(sl_mask==1);
    sdim_slices(z)=length(indices);
    if (length(indices)<5*comps)
      skipped(z)=1;
      comp_r(z)=1;
      max_comp_r(z)=0;
      comp_c(z)=1;
      max_comp_c(z)=0;
      continue;
    end
    sparsed_resp=sl_resp(indices);
    sparsed_card=sl_card(indices);
    for j=1:comps
      sparsed_m(:,j)=m(indices,j);
    end
    for j=1:comps
      timeseries=squeeze(A(j,:));
      
      % variance normalize
      D(j,:)=timeseries/std(timeseries);
      r_r(j)=corr(sparsed_resp,sparsed_m(:,j));
      r_c(j)=corr(sparsed_card,sparsed_m(:,j));
    end
    
    r_r(isnan(r_r))=0;  r_c(isnan(r_c))=0;
    slice_timeseries(z,:,:)=D;
    % use the maximum absolute coupling component, since sign of components is arbitrary
    comp_r(z)=find(abs(r_r)==max(abs(r_r)),1);
    max_comp_r(z)=r_r(comp_r(z));
    comp_c(z)=find(abs(r_c)==max(abs(r_c)),1);
    max_comp_c(z)=r_c(comp_c(z));
    corr_r(z,:)=r_r;  corr_c(z,:)=r_c;
  else
    disp([num2str(z) ' slice ICA file does not exist.' ])
  end
end

% take maximum coupling components
skip=zeros(zdim,1);
for z=1:zdim
  if (numel(find(zstart==z))==0)
    slice_m_r(:,z)=zeros(xdim*ydim,1);
    slice_m_c(:,z)=zeros(xdim*ydim,1);
    temporal_c(z,:)=zeros(tdim,1);
    temporal_r(z,:)=zeros(tdim,1);
    comp_r(z)=1;
    max_comp_r(z)=0;
    comp_c(z)=1;
    max_comp_c(z)=0;
    skip(z)=1;
    slice_timeseries(z,:,:)=zeros(comps,tdim);
    continue;
  end
  temporal_r(z,:)=squeeze(slice_timeseries(z,comp_r(z),:)); 
  if (temporal_r(z,:)~=zeros(1,tdim))
    temporal_r(z,:)=temporal_r(z,:)/std(temporal_r(z,:));
  end
  temporal_c(z,:)=squeeze(slice_timeseries(z,comp_c(z),:));
  if (temporal_c(z,:)~=zeros(1,tdim))
    temporal_c(z,:)=temporal_c(z,:)/std(temporal_c(z,:));
  end
  if (max_comp_r(z)<0)
    temporal_r(z,:)=-1*temporal_r(z,:);
    % disp(['resp ' num2str(z) ' is flipped'])
  end
  if (max_comp_c(z)<0)
    temporal_c(z,:)=-1*temporal_c(z,:);
    disp(['cardiac ' num2str(z) ' is flipped'])
  end
  load(sprintf('pestica5_%dcomps_slice%d.mat',comps,z),'m');
  slice_m_r(:,z)=m(:,comp_r(z));
  slice_m_c(:,z)=m(:,comp_c(z));
end

% find cutoff for the interpolation over poorly-identified slices
keep_card_slices=zeros(zdim,1);
keep_resp_slices=zeros(zdim,1);
for z=1:zdim
  cutoff(z)=get_correlation_threshold(comps,sdim_slices(z));
  % this cutoff is poorly calculated as there are spatial correlations present in the data
  % dirty approx, 1/4th the resolution due to in-plane smoothing
  %cutoff(z)=get_correlation_threshold(comps,round(sdim_slices(z)/4));
  if (abs(max_comp_c(z))>=cutoff(z))
    keep_card_slices(z)=1;
  end
  if (abs(max_comp_r(z))>=cutoff(z))
    keep_resp_slices(z)=1;
  end
end

if (exist('TE')~=1)
%   TE=29;
  TE = 0; % 
end
TE=double(TE);
zdim=double(zdim);
if (length(find(keep_card_slices==1))==0)
  disp(['no slices can be trusted for cardiac (below significance) in ' num2str(find(keep_card_slices==1)) ' slice(s), taking those above avg corr']);
  keep_card_slices(find(abs(max_comp_c)>mean(abs(max_comp_c))))=1;
end
if (length(find(keep_resp_slices==1))==0)
  disp(['no slices can be trusted for respiratory (below significance) in ' num2str(find(keep_card_slices==1)) ' slice(s), taking those above avg corr']);
  keep_resp_slices(find(abs(max_comp_r)>mean(abs(max_comp_r))))=1;
end

keep_resp_slices_sms = zeros(1,zmbdim);
keep_card_slices_sms = zeros(1,zmbdim);
if MBacc > 1
  for z = 1:zmbdim
%     zz = find(uniq_slice_timing_sec == uniq_slice_timing_sec(z)); debugged 20210527 (ws)
    zz = find(slice_timing_sec == uniq_slice_timing_sec(z));
    zz_sms = zz(find(keep_resp_slices(zz)));
    temporal_r_sms(z,:) = mean(temporal_r(zz_sms,:),1);
    zz_sms = zz(find(keep_card_slices(zz)));
    temporal_c_sms(z,:) = mean(temporal_c(zz_sms,:),1);
    keep_resp_slices_sms(z) = ceil(sum(keep_resp_slices(z:zmbdim:end))/MBacc);
    keep_card_slices_sms(z) = ceil(sum(keep_card_slices(z:zmbdim:end))/MBacc);
  end
else
  temporal_r_sms = temporal_r;
  temporal_c_sms = temporal_c;
  keep_resp_slices_sms = keep_resp_slices;
  keep_card_slices_sms = keep_card_slices;
end

% consider signal
card_zeroslice = length(find(keep_card_slices_sms==0));
resp_zeroslice = length(find(keep_resp_slices_sms==0));
if card_zeroslice
  disp(['Note that cardiac PESTICA will be interpolated at ' num2str(card_zeroslice) ' of ' num2str(zdim) ' slices'])
end
if resp_zeroslice
  disp(['Note that respiratory PESTICA will be interpolated at ' num2str(resp_zeroslice) ' of ' num2str(zdim) ' slices'])
end
card_est = convert_slicextime_to_timeseries(temporal_c_sms,uniq_acq_order,keep_card_slices_sms);
resp_est = convert_slicextime_to_timeseries(temporal_r_sms,uniq_acq_order,keep_resp_slices_sms);

save(sprintf([Ptemplate '_matrices_%dcomps.mat'],comps),'slice_m_r','slice_m_c','keep_card_slices','keep_resp_slices','skip','corr_c','corr_r','max_comp_r','max_comp_c','cutoff');

