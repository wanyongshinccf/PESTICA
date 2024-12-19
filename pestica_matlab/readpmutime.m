function [pmu LogStartTime LogStopTime] = readpmutime(fname)
temp=textread(fname,'%s', 'delimiter','\n', 'bufsize', 3200000);
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
%%%%%%

tmp = temp{find(strncmpi(temp,'LogStartMDHTime',15))};
tmp(1:strfind(tmp,':'))=[];
LogStartTime = str2num(tmp);
tmp = temp{find(strncmpi(temp,'LogStopMDHTime',14))};
tmp(1:strfind(tmp,':'))=[];
LogStopTime = str2num(tmp);

% tmp = pmustr{find(strncmpi(pmustr,'LogStartMPCUTime',16))};
% tmp(1:strfind(tmp,':'))=[];
% tp_start2 = str2num(tmp);
% tmp = pmustr{find(strncmpi(pmustr,'LogStopMPCUTime',15))};
% tmp(1:strfind(tmp,':'))=[];
% tp_end2 = str2num(tmp);

