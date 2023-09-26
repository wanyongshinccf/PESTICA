function rw_pmu_siemens(ep2d_filename,pmufileprefix,nVolEndCutOff)
% function rw_pmu_HCP(ep2d_filename,pmufileprefix,nVolEndCutOff)
% initialized by W.S, CCF, 20170925
%
% read pmu data, remove etra points, and resampled to match with 2.5ms 
% sampling rate.

if ~exist('nVolEndCutOff');     nVolEndCutOff = 0;  end

% update and inject slice timing 
[err,Info] = BrikInfo(ep2d_filename);
xdim=Info.DATASET_DIMENSIONS(1);
ydim=Info.DATASET_DIMENSIONS(2);
zdim=Info.DATASET_DIMENSIONS(3);
tdim=Info.DATASET_RANK(2);
TR=double(Info.TAXIS_FLOATS(2));          
[TRsec TRms] = TRtimeunitcheck(TR);

% read MB factor
[MBacc zmbdim uniq_slice_timing uniq_acq_order] = SMSacqcheck(TRsec, zdim, Info.TAXIS_OFFSETS);

% 
downsamplerate=50;  % ms
if length(strfind(pmufileprefix,'txt'))
  pmufile = pmufileprefix;
else
  pmufile = [pmufileprefix '.txt'];
end

% check if physio data exists
if exist(pmufile)
  fname_all  = load(pmufile);
  fname_ext  = fname_all(:,1);
  fname_resp = fname_all(:,2);
  fname_card = fname_all(:,3);
else
  disp('Error: PMU file does not exist.')
  return
end

% check quality
if length(find(fname_card == 4095))
  disp(['Cardiac signals are saturated in ' num2str(length(find(fname_card == 4095))) ' points'])
end
if length(find(fname_card == 0))
  disp(['Cardiac signals are nulled in ' num2str(length(find(fname_card == 0))) ' points'])
end
if length(find(fname_resp == 4095))
  disp(['Respiratory signals are saturated in ' num2str(length(find(fname_resp == 4095))) ' points'])
end
if length(find(fname_resp == 0))
  disp(['Respiratory signals are nulled in ' num2str(length(find(fname_resp == 0))) ' points'])
end

% check trigger file
diffext = diff(fname_ext);
tmp = find(diffext==1);
xtrigs = [ 1; tmp] ;
SR_ext = round(mean(diff(xtrigs)))/TRsec;
disp(['Trigger sampling rate is ' num2str(SR_ext) ' Hz'])
ttable = 0: round(mean(diff(xtrigs)));
ttable = ttable./ttable(end)*1000;
card_ext = [];
resp_ext = [];
for n = 1:length(xtrigs)-1
  ttable_trig = [0 : xtrigs(n+1)- xtrigs(n)];
  ttable_trig = ttable_trig./ttable_trig(end)*1000 ;
  
  card = fname_card(xtrigs(n):xtrigs(n+1));
  resp = fname_resp(xtrigs(n):xtrigs(n+1));
  
  card_tmp = pchip(ttable_trig,card,ttable);
  resp_tmp = pchip(ttable_trig,resp,ttable);
  
  card_ext = [card_ext card_tmp(1:end-1)];
  resp_ext = [resp_ext resp_tmp(1:end-1)];
end

card_ext = [card_ext fname_card(xtrigs(end):xtrigs(end)+round(mean(diff(xtrigs))) -1 )'];
resp_ext = [resp_ext fname_resp(xtrigs(end):xtrigs(end)+round(mean(diff(xtrigs))) -1 )'];
ext_ext = zeros(size(card_ext));
ext_ext(1:round(mean(diff(xtrigs))):end)=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%
% downsampl, if necesary %
%%%%%%%%%%%%%%%%%%%%%%%%%%
if SR_ext ~= downsamplerate
  disp(['fext is downsamled with ' num2str(downsamplerate) 'Hz.'])
end

fext  = ext_ext(1:SR_ext/downsamplerate:end);
fcard = card_ext(1:SR_ext/downsamplerate:end);
fresp = resp_ext(1:SR_ext/downsamplerate:end);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % additionally, normalization %
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mf=mean(fcard);
% fcard=(fcard-mf)/std(fcard);
% mf=mean(fresp);
% fresp=(fresp-mf)/std(fresp);
    
% consider the truncated EPI 
trign = length(xtrigs);
nVolStartCutOff = trign - tdim - nVolEndCutOff;
nphyioinTR = downsamplerate*Info.TAXIS_FLOATS(2);

if nVolEndCutOff > 0 
  disp(['PMU data is truncated at last with ' num2str(nVolEndCutOff) ' of EPI vol'])
  fext  = fext(1:end-nphyioinTR*nVolEndCutOff);
  fcard = fcard(1:end-nphyioinTR*nVolEndCutOff);
  fresp = fresp(1:end-nphyioinTR*nVolEndCutOff);
end

if nVolStartCutOff > 0
  disp(['PMU data is truncated at first with ' num2str(nVolStartCutOff) ' of EPI vol'])
  fext  = fext(nphyioinTR*nVolStartCutOff+1:end);
  fcard = fcard(nphyioinTR*nVolStartCutOff+1:end);
  fresp = fresp(nphyioinTR*nVolStartCutOff+1:end);
end

% save pmu data
fp=fopen('card_raw_pmu.dat','w'); 
fprintf(fp,'%g\n',fcard); fclose(fp); 
fp=fopen('resp_raw_pmu.dat','w'); 
fprintf(fp,'%g\n',fresp); fclose(fp);
