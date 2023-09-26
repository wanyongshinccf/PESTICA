function [fpmu_est]=view_and_correct_estimator(pmu_est,ep2d_filename,physio,batchflag)

% BrikInfo only works on AFNI BRIK format files
Opt.Format = 'matrix';
[err, ainfo]=BrikInfo(ep2d_filename);
zdim=ainfo.DATASET_DIMENSIONS(3);
TR=double(ainfo.TAXIS_FLOATS(2));
slice_timing = load('tshiftfile.1D');

% correct milli second unit of TR and slice timing
[TRsec TRms] = TRtimeunitcheck(TR);
[slice_timing_sec slice_timing_ms] = TRtimeunitcheck(slice_timing);

% check SMS acquisition
[MBacc zmbdim] = SMSacqcheck(TRms, zdim, slice_timing_ms);

disp(' ');
disp(sprintf('From %s header, using slices=%d and TR=%f',ep2d_filename,zdim,TRsec));
disp(' ');

fileprefix='pmu_';
% for Siemens PMU data, sample rate is 50Hz
f_s=50.0;
% otherwise it is slice acquisition rate
if (length(physio)==1)
  fileprefix='pestica_';
  %f_s must be in Hz, for the sample rate of the estimator (slices per second)
  f_s=zmbdim/TRsec;
end
if (batchflag==1)
  % use the default range observed in a range of human MRI scans (not ideal): cardiac 48-85bpm, resp 10-24bpm
  if (strncmp(physio,'c',1))
    x=[48 85];
    titlestr='Cardiac';
  end
  if (strncmp(physio,'r',1))
    x=[10 24];
    titlestr='Respiratory';
  end
  h = figure('visible','off');
  plot(linspace(60*f_s/length(pmu_est),60*f_s,length(pmu_est)),abs(fft(pmu_est).^2),'k','linewidth',2);
  set(gca,'fontsize',16);
  xlabel('sampling frequency (bpm)')
  title(titlestr);
  xlim(x);
  saveas(h,sprintf('%sbatch_est_fft_%s.png',fileprefix,physio(1)));
  close
  x=x/f_s;
  x=x/60;
  if (x(1)<f_s/length(pmu_est));
    x(1)=f_s/length(pmu_est);
  end
  fpmu_est=tfilter_fft(pmu_est-tfilter_fft(pmu_est,x(1)),x(2));
  return
end

h=figure;
plot(linspace(60*f_s/length(pmu_est),60*f_s,length(pmu_est)),abs(fft(pmu_est).^2),'k','linewidth',2);
set(gca,'fontsize',16);
xlabel('sampling frequency (bpm)')
xlim([0 120]);
if (exist('physio','var')==0)
  physio='';
end
% set slightly wider limits if doing visual selection
if (strncmp(physio,'c',1))
  xlim([45 88]);
  titlestr='Cardiac';
end
if (strncmp(physio,'r',1))
  xlim([9 28]);
  titlestr='Respiratory';
end
title(titlestr);
% zoom in horizontally on the pmu peak
a=version('-release');
if (str2num(a(1:4))<2007)
  %disp('if version is less than R2007a, zoom does not have this functionality');
  zoom;
    disp('');
    disp('*************************************************************');
    disp('*************************************************************');
  disp('hit enter (at this matlab command prompt) when you have zoomed _around_ (only horizontal');
  disp('zoom matters) a reasonable pmu peak cardiac 62+-8bpm (range 48-85), resp 17+-4bpm (range 10-24)');
  disp('double-click to re-zoom to original width');
else
  %disp('if version is greater than R2012a, Handle Graphics is unsupported in -nojvm mode (however it still seems to work fine)');
  h = zoom;
  zoom;
  set(h,'Motion','horizontal','Enable','on');
  disp('hit enter (at this matlab command prompt) when you have zoomed on a reasonable pmu');
  if (strncmp(physio,'c',1))
    disp('');
    disp('*************************************************************');
    disp('*************************************************************');
    disp('Range of typical human cardiac rate: 62+-8bpm (range 48-85)');
    disp('use a buffer of at least 20bpm around the peaks you like for cardiac');
    disp('*************************************************************');
    disp('*************************************************************');
  end
  if (strncmp(physio,'r',1))
    disp('');
    disp('*************************************************************');
    disp('*************************************************************');
    disp('Range of typical human respiration rate: 17+-4bpm (range 10-24)');
    disp('use a buffer of at least 10bpm around the peaks you like for respiration');
    disp('*************************************************************');
    disp('*************************************************************');
  end
end
pause;
saveas(gcf,sprintf('%sest_fft_%s.png',fileprefix,physio(1)));
x=xlim/f_s;
x=x/60;
if (x(1)<f_s/length(pmu_est));
  x(1)=f_s/length(pmu_est);
end
fpmu_est=tfilter_fft(pmu_est-tfilter_fft(pmu_est,x(1)),x(2));
close

