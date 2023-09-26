function [pmu pmupeak tp_startMDH tp_endMDH tp_startMPCU tp_endMPCU ] = readpmu_VENX(fname)

fID=fopen(fname);
temp=textscan(fID,'%s','delimiter','\n'); pmustr = temp{1};

pmusig = pmustr{1};

strstart = strfind(pmusig,'5002');
strend   = strfind(pmusig,'6002');
if length(strstart) == length(strend)
  for n = length(strstart):-1:1
    pmusig(strstart(n):strend(n)+4)=[];
  end
else  
  disp('No string is added')
end
pmu=str2num(pmusig);

% remove four words and last word
pmu = pmu(5:end-1);
% remove artificial trigs
pmupeak = find(pmu>4099);
pmupeak = pmupeak - [1:length(pmupeak)];

% save pmu under 4095
pmu = pmu(find(pmu<4097));

% find 
tmp = pmustr{find(strncmpi(pmustr,'LogStartMDHTime',15))};
tmp(1:strfind(tmp,':'))=[];
tp_startMDH = str2num(tmp);
tmp = pmustr{find(strncmpi(pmustr,'LogStopMDHTime',14))};
tmp(1:strfind(tmp,':'))=[];
tp_endMDH = str2num(tmp);

tmp = pmustr{find(strncmpi(pmustr,'LogStartMPCUTime',16))};
tmp(1:strfind(tmp,':'))=[];
tp_startMPCU = str2num(tmp);
tmp = pmustr{find(strncmpi(pmustr,'LogStopMPCUTime',15))};
tmp(1:strfind(tmp,':'))=[];
tp_endMPCU = str2num(tmp);
