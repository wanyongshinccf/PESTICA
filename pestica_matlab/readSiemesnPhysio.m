function [fext, fcard,fresp,fecg]=readSiemesnPhysio(fname,TR,samplerate,downsamplerate)
% this function read PMU data (e.g. **.ext, *.resp, *.card) 
% created by Wanyong Shin, CCF 20150527

if ~exist('samplerate');      samplerate=400;     end;  % 1/sec
if ~exist('downsamplerate');  downsamplerate=50;  end;  % 1/sec

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. triggering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trigger file always must exist
ext = readpmu(sprintf('%s.ext',fname));

% newly added to consider signals from original box
diffext = diff(ext);
tmp = abs(find(diffext>0) - find(diffext<0));
% considering the smallest TR as 100(50)ms with 200(400) Hz trigger in fMRI
if mean(tmp) > 20 
  disp('PMU data should be measured using the original trigger box.')
  ext = abs(diffext);
end

% set trigger point of the first points among trigger block
ext(find(diff(ext)==1)+1)=10;
% find the trigger data points (sampling mesh)
xtrigs=find(ext(1:end)==10);

% find time stamp
[tp_start tp_end] = readlogtime(sprintf('%s.ext',fname));
ms_dur_ext = tp_end - tp_start; % [ms]

% set tdim based on number of trigs seen, check if dataset tdims are lower (typically if you 3dcopy or 3dvolreg less vols)
tdim=length(xtrigs);


% check 
xlen=length(ext(xtrigs(1):xtrigs(end)-1))/(tdim-1);
SR_ext = round(xlen/TR);
disp(['Trigger sampling rate is ' num2str(SR_ext) ' Hz'])
if ~(SR_ext == 400 || SR_ext == 200)
  disp('Warning: external trigger sampling rate is not either of 200Hz(VB) or 400Hz(VD)');
  disp('Trigger file might be corrupted.')
end
ms_diff_ext = ms_dur_ext - (length(ext)/SR_ext)*1000; 
if abs(ms_dur_ext / (length(ext)/SR_ext)/1000 - 1) > 0.01
  disp('Warning: exterianl trigger MDH time might not be accruate (> 1% discrepancy).')
end
if abs(ms_diff_ext/1000) > TR
  disp('Warning: external logging end time might not be accruate ( > TR discrepancy).')
end

% calculate time point 
tp_start_ext = tp_start + xtrigs(1)*(1/SR_ext)* 1000; % [ms]
tp_end_ext   = tp_start + (xtrigs(end)+xlen -1) *(1/SR_ext)* 1000; %[ms]

% take the triggers only from first volume start to last volume END
fext = ext(xtrigs(1):xtrigs(end)+xlen -1);
fextlen = int32(TR*tdim*SR_ext);

% sanity checking
if (fextlen>length(fext))
  disp(['Warning: length is not as calculated: add ' num2str(fextlen - length(fext)) ' zero point(s) in fext']);
  fext(end+1:fextlen)=0;
elseif (fextlen<length(fext))
  disp(['Warning: length is not as calculated: remove last ' num2str(length(fext) - fextlen) ' point(s) in fext']);
  fext(fextlen+1:end) = [];
end

fext(find(fext<10))=0;
fext(find(fext==10))=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. respiratory signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
respflag=0;
fnamer=sprintf('%s.resp',fname);
if (exist(fnamer)~=0)
 respflag=1;
 [resp respp] = readpmu(fnamer);
 resppeak = zeros(size(resp));
 resppeak(respp)=10;
 [tp_start_resp tp_end_resp] = readlogtime(fnamer);
  ms_dur_resp = tp_end_resp - tp_start_resp;
  
  % check 
  SR_resp = round(length(resp) / ms_dur_resp*1000/50)*50;
  disp(['Respiratory sampling rate is ' num2str(SR_resp) ' Hz'])
  if ~(SR_resp == 400 || SR_resp == 50)
    disp('Warning: respiratory sampling rate is not either of 50Hz(VB) or 400Hz(VD)');
  end
  fresplen = int32(TR*tdim*SR_resp);
  ms_diff_resp = ms_dur_resp - (length(resp)/SR_resp)*1000; 
  if abs(ms_dur_resp/(length(resp)/SR_resp)/1000 -1) > 0.01
    disp('Warning: respiratory MDH time might not be accruate (> 1% discrepancy).')
  end
  if abs(ms_diff_resp/1000) > TR
    disp('Warning: respiratory logging end time might not be accruate ( > TR discrepancy).')
  end
end

if (respflag)
  % calculate time point 
  X = tp_start_resp: 1/SR_resp*1000 : tp_end_resp + 5*1000*TR ; % add extra 10 points
  X = X(1:length(resp));
  
  XX = tp_start_ext: 1/SR_resp*1000 :  tp_end_ext + 5*1000*TR; % add extra 10 pts
  XX = XX(1:fresplen);

  fresp=pchip(X,resp,XX);
  fresppeak = pchip(X,resppeak,XX);
else
  fresp=zeros(1,extlen);
  fresppeak=zeros(1,extlen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. cardiac signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cardflag=0;
fnamec=sprintf('%s.puls',fname);
if (exist(fnamec)~=0)
  cardflag=1;
  [card cardp] = readpmu(fnamec);
  cardpeak = zeros(size(card));
  cardpeak(cardp)=10;
  [tp_start_card tp_end_card] = readlogtime(fnamec);
  ms_dur_card = tp_end_card - tp_start_card;
  
  % check 
  SR_card = round(length(card) / ms_dur_card*1000/50)*50;
  disp(['Cardiac sampling rate is ' num2str(SR_card) ' Hz'])
  
  if ~(SR_card == 400 || SR_card == 50)
    disp('Warning: Cardiac sampling rate is not either of 50Hz(VB) or 400Hz(VD)');
  end
  fcardlen = int32(TR*tdim*SR_card);
  ms_diff_card = ms_dur_card - (length(card)/SR_card)*1000; 
  if abs(ms_dur_card/(length(card)/SR_card)/1000 -1) > 0.010
    disp('Warning: cardiac MDH time might not be accruate (> 1% discrepancy).')
  end
  if abs(ms_diff_card/1000) > TR
    disp('Warning: cardiac logging end time might not be accruate ( > TR discrepancy).')
  end
end

if (cardflag)
  % calculate time point 
  X = tp_start_card: 1/SR_card*1000 :tp_end_card + 5*1000*TR; % add extra 10 points
  X = X(1:length(card));
  
  XX = tp_start_ext: 1/SR_card*1000: tp_end_ext + 5*1000*TR; % add extra 10 pts
  XX = XX(1:fcardlen);

  fcard=pchip(X,card,XX);
  fcardpeak =pchip(X,cardpeak,XX);
else
  fcard=zeros(1,extlen);
  fcardpeak =zeros(1,extlen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. ecg signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ecgflag=0;
fnamec=sprintf('%s.ecg',fname);
if (exist(fnamec)==0)
  ecgflag=0;
  % no ecg data here %
else
  fecg=zeros(1,fextlen);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
% downsampl, if necesary %
%%%%%%%%%%%%%%%%%%%%%%%%%%
if SR_ext ~= downsamplerate
  disp('')
  disp(['fext is downsamled with ' num2str(downsamplerate) 'Hz.'])
  disp('')
end
fext = fext(1:SR_ext/downsamplerate:end);
  
if respflag
  if SR_resp ~= downsamplerate
    disp('')
    disp(['fresp is downsamled with ' num2str(downsamplerate) 'Hz.'])
    disp('')
  end
  fresp = fresp(1:SR_resp/downsamplerate:end);
end
if cardflag
  if SR_card ~= downsamplerate
    disp(['fcard is downsamled with ' num2str(downsamplerate) 'Hz.'])
    disp('')
  end
  fcard = fcard(1:SR_card/downsamplerate:end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% additionally, normalization %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mf=mean(fcard);
fcard=(fcard-mf)/std(fcard);
mf=mean(fresp);
fresp=(fresp-mf)/std(fresp);
if (ecgflag)
 mf=mean(fecg1);
 fecg1=(fecg1-mf)/std(fecg1);
 mf=mean(fecg2);
 fecg2=(fecg2-mf)/std(fecg2);
 mf=mean(fecg3);
 fecg3=(fecg3-mf)/std(fecg3);
end

function [pmu pmupeak] = readpmu(fname)
temp=textread(fname,'%s', 'delimiter','\n', 'bufsize', 800000);
pmustr = temp{1};
strstart = strfind(pmustr,'5002');
strend   = strfind(pmustr,'6002');
if length(strstart) == length(strend)
  for n = length(strstart):-1:1
    pmustr(strstart(n):strend(n)+4)=[];
  end
else  
  disp('No string is added')
end
pmu=str2num(pmustr);

% remove four words and last word
pmu = pmu(5:end-1);
% remove artificial trigs
pmupeak = find(pmu>4099);
pmupeak = pmupeak - [1:length(pmupeak)];

pmu = pmu(find(pmu<4097));

function [tp_start1 tp_end1 tp_start2 tp_end2 ] = readlogtime(fname)
pmustr=textread(fname,'%s', 'delimiter','\n', 'bufsize', 800000);
tmp = pmustr{find(strncmpi(pmustr,'LogStartMDHTime',15))};
tmp(1:strfind(tmp,':'))=[];
tp_start1 = str2num(tmp);
tmp = pmustr{find(strncmpi(pmustr,'LogStopMDHTime',14))};
tmp(1:strfind(tmp,':'))=[];
tp_end1 = str2num(tmp);

tmp = pmustr{find(strncmpi(pmustr,'LogStartMPCUTime',16))};
tmp(1:strfind(tmp,':'))=[];
tp_start2 = str2num(tmp);
tmp = pmustr{find(strncmpi(pmustr,'LogStopMPCUTime',15))};
tmp(1:strfind(tmp,':'))=[];
tp_end2 = str2num(tmp);

