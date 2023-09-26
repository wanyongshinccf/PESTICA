function [fext, fcard,fresp,fecg]=readSiemesnPhysio_new(fname,TR,samplerate,downsamplerate)
% this function read PMU data (e.g. **.ext, *.resp, *.card) 
% created by Wanyong Shin, CCF 20170216

if ~exist('samplerate');      samplerate=400;     end;  % 1/sec
if ~exist('downsamplerate');  downsamplerate=50;  end;  % 1/sec

% check if physio data exists
fname_ext =sprintf('%s.ext',fname);
fname_resp=sprintf('%s.resp',fname);
fname_card=sprintf('%s.puls',fname);

flag_fname_ext=0;  if exist(fname_ext);  flag_fname_ext=1; end
flag_fname_resp=0; if exist(fname_resp); flag_fname_resp=1; end
flag_fname_card=0; if exist(fname_card); flag_fname_card=1; end

if flag_fname_ext == 0
  disp('Error: external trigger file does not exist');
  return
end
if flag_fname_card == 0
  disp('Error: cardiac physio file does not exist');
  return
end
if flag_fname_resp == 0
  disp('Error: repiratory physio file does not exist');
  return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. triggering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ext = readpmu(fname_ext);

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
xtrigs=find(ext(1:end)==10);
tdim=length(xtrigs);

% find time stamp
[tp_start_ext tp_end_ext] = readlogtime(fname_ext);
ms_dur_ext = tp_end_ext - tp_start_ext; % [ms]

resp= readpmu(fname_resp);
[tp_start_resp tp_end_resp] = readlogtime(fname_resp);
ms_dur_resp = tp_end_resp - tp_start_resp; % [ms]

card= readpmu(fname_card);
[tp_start_card tp_end_card] = readlogtime(fname_card);
ms_dur_card = tp_end_card - tp_start_card; % [ms]

% check the data quality 
tp_ext  = round(2*ms_dur_ext/length(ext))/2;   SR_ext  = 1000/tp_ext;
tp_card = round(2*ms_dur_card/length(card))/2; SR_card = 1000/tp_card;
tp_resp = round(2*ms_dur_resp/length(resp))/2; SR_resp = 1000/tp_resp;

disp(['Trigger sampling rate is ' num2str(SR_ext) ' Hz'])
if ~(SR_ext == 400 || SR_ext == 200)
  disp('Warning: external trigger sampling rate is not either of 200Hz(VB) or 400Hz(VD)');
  disp('Trigger file might be corrupted.')
end
disp(['Respiratory sampling rate is ' num2str(SR_resp) ' Hz'])
if ~(SR_resp == 400 || SR_resp == 50)
  disp('Warning: respiratory sampling rate is not either of 50Hz(VB) or 400Hz(VD)');
end
disp(['Cardiac sampling rate is ' num2str(SR_card) ' Hz'])
if ~(SR_card == 400 || SR_card == 50)
  disp('Warning: cardiac sampling rate is not either of 50Hz(VB) or 400Hz(VD)');
end

% note that ms_dur_ext/length(ext) should be integer, but it is not in
% reality. Assume the starting time point is correct, not consider the end
% time point

% retiming of external trigger signal
ttable_ext  = 0:tp_ext:(length(ext)-1)*tp_ext;
ttable_card = 0:tp_card:(length(card)-1)*tp_card;
ttable_card = ttable_card + tp_start_card - tp_start_ext;
ttable_resp = 0:tp_resp:(length(resp)-1)*tp_resp;
ttable_resp = ttable_resp + tp_start_resp - tp_start_ext;

TRms = TR*1000;
tp_TR = TRms/tp_ext;
ttable_TR = 0:tp_ext:(tp_TR-1)*tp_ext;

if ~length(find(ttable_card > ttable_ext(xtrigs(end)) + (tp_TR-1)*tp_ext))
  addtp = round((ttable_ext(xtrigs(end)) + (tp_TR-1)*tp_ext - ttable_card(end)) / tp_card) + 10;
  ttable_card(end:end+addtp) = ttable_card(end):tp_card:ttable_card(end)+addtp*tp_card;
  card(end+1:end+addtp) = mean(card);
end
if ~length(find(ttable_resp > ttable_ext(xtrigs(end)) + (tp_TR-1)*tp_ext))
  addtp = round((ttable_ext(xtrigs(end)) + (tp_TR-1)*tp_ext - ttable_resp(end)) / tp_resp) + 10;
  ttable_resp(end:end+addtp) = ttable_resp(end):tp_resp:ttable_resp(end)+addtp*tp_resp;
  resp(end+1:end+addtp) = mean(resp);
end

ext_ext=[];card_ext=[];resp_ext=[];
for n=1:length(xtrigs)
  ttable_TR =  [0:tp_ext:(tp_TR-1)*tp_ext] + ttable_ext(xtrigs(n));  
  ext_ext =  [ext_ext ones(1,SR_ext/downsamplerate) zeros(1,tp_TR-SR_ext/downsamplerate)];
  card_ext = [card_ext pchip(ttable_card,card,ttable_TR)];
  resp_ext = [resp_ext pchip(ttable_resp,resp,ttable_TR)];
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%
% downsampl, if necesary %
%%%%%%%%%%%%%%%%%%%%%%%%%%
if SR_ext ~= downsamplerate
  disp(['fext is downsamled with ' num2str(downsamplerate) 'Hz.'])
end
fext  = ext_ext(1:SR_ext/downsamplerate:end);
fcard = card_ext(1:SR_ext/downsamplerate:end);
fresp = resp_ext(1:SR_ext/downsamplerate:end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% additionally, normalization %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% mf=mean(fcard);
% fcard=(fcard-mf)/std(fcard);
% mf=mean(fresp);
% fresp=(fresp-mf)/std(fresp);

function [pmu pmupeak] = readpmu(fname)
  temp=textread(fname,'%s', 'delimiter','\n', 'bufsize', 1200000);

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
  pmustr=textread(fname,'%s', 'delimiter','\n', 'bufsize', 1200000);

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

