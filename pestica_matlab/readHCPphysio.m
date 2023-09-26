function [fext, fcard,fresp,fecg]=readHCPphysio(fname,Info,samplerate,downsamplerate)
% this function read PMU data (e.g. **.ext, *.resp, *.card) 
% created by Wanyong Shin, CCF 20170216

if ~exist('samplerate');      samplerate=400;     end;  % 1/sec
if ~exist('downsamplerate');  downsamplerate=50;  end;  % 1/sec

% check if physio data exists
if exist(fname)
  fname_all  = load(fname);
  fname_ext  = fname_all(:,1);
  fname_resp = fname_all(:,2);
  fname_card = fname_all(:,3);
else
  disp('Error: PMU file does not exist.')
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. triggering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diffext = diff(fname_ext);
tmp = find(diffext==1);
xtrigs = [ 1; tmp] ;
round(mean(diff(xtrigs)))/720


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

ext_ext=[];card_ext=[];resp_ext=[];
for n=1:length(xtrigs)
  ttable_TR =  [0:tp_ext:(tp_TR-1)*tp_ext] + ttable_ext(xtrigs(n));  
  ext_ext =  [ext_ext 1 zeros(1,tp_TR-1)];
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
mf=mean(fcard);
fcard=(fcard-mf)/std(fcard);
mf=mean(fresp);
fresp=(fresp-mf)/std(fresp);

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

