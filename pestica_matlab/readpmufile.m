function [pmusig LogStartTime LogStopTime] = readpmufile(fname)


% FORMAT OF THE PHYSIO FILES:
% The first 4 values are don't care
% Additional header data between identifiers 5002 and 6002 are also don't care
% 5000 = Trigger ON (trigger detected by the Syngo software) (rising edge)
% 6000 = Trigger OFF (trigger detected by the Syngo software)
% 5003 = end of data stream, followed by statistics
% 6003 = end of file

% read pmu files
fid = fopen(fname);
sig = textscan(fid,'%u16'); %Read data until end of u16 data.
data = textscan(fid,'%s','delimiter','\n'); %Read data until end of u16 data.
fclose(fid);

% read u16 pmu data
pmusig = sig{1};

% remove four words and last word
pmusig = pmusig(5:end-1);

% remove artificial trigs, if any
pmusig = double(pmusig(find(pmusig<4097)));

% reading mdh info
pmulog = data{1};

tmp = pmulog{find(strncmpi(pmulog,'LogStartMDHTime',15))};
tmp(1:strfind(tmp,':'))=[];
LogStartTime = str2num(tmp);
tmp = pmulog{find(strncmpi(pmulog,'LogStopMDHTime',14))};
tmp(1:strfind(tmp,':'))=[];
LogStopTime = str2num(tmp);

tmp = pmulog{find(strncmpi(pmulog,'LogStartMPCUTime',16))};
tmp(1:strfind(tmp,':'))=[];
tp_start2 = str2num(tmp);
tmp = pmulog{find(strncmpi(pmulog,'LogStopMPCUTime',15))};
tmp(1:strfind(tmp,':'))=[];
tp_end2 = str2num(tmp);
