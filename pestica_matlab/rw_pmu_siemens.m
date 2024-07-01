function rw_pmu_siemens(ep2d_filename,pmufileprefix,nVolEndCutOff)

if ~exist('nVolEndCutOff')
  nVolEndCutOff = 0;
end

[err,Info] = BrikInfo(ep2d_filename);
downsamplerate=50;  

if exist([pmufileprefix '.ext'])
  % read pmu from Siemens
  [fext,fcard,fresp] = readSiemesnPhysio(pmufileprefix,Info.TAXIS_FLOATS(2)); 
elseif exist([pmufileprefix '_Info.log'])
  [fext,fcard,fresp] = readCMRRPhysio_CCF(pmufileprefix,Info.TAXIS_FLOATS(2));
else
  disp('ERROR: pmu postfix should be ext or log')
  return
end

% consider the truncated EPI 
trign = length(find(fext==1));
tdim_epi = Info.TAXIS_NUMS(1);
nVolStartCutOff = trign - tdim_epi - nVolEndCutOff;
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