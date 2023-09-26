function resppmucor(ifname, rfname)

fID=fopen(ifname);
temp=textscan(fID,'%s','delimiter','\n'); 
pmu = temp{1}; pmuraw = pmu{1};

rmstr = '33554432 98304 67108864 163840';

rmstr_start = strfind(pmuraw,rmstr);
rmstr_end = rmstr_start+length(rmstr);

if length(rmstr_start)
pmu_end = rmstr_start-1;
pmu_end(end+1) = length(pmuraw);
pmu_start(2:length(pmu_end)) = rmstr_end+1;
pmu_start(1)= 1;

pmucor='';
for n = 1:length(rmstr_start)
    pmucor = [pmucor pmuraw(pmu_start(n):pmu_end(n))];
end
pmu{1} = pmucor;

fID = fopen(rfname,'w');
for n = 1:length(pmu)-1
  fwrite(fID,pmu{n});
  fprintf(fID,'\n');
end
fwrite(fID,pmu{end});
fclose(fID);
else
  disp('Your resp file might be already corrected.');
end