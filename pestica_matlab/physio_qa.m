function physio_qa(ep2d_filename,pmuflag)
%function physio_qa(ep2d_filename,pmuflag)
% script reads in physio and fit data in local directory and pestica/ subdirectory
% plot histograms of periodicities, plot IRFs, report number of voxels significantly coupled
%
% make AFNI shots of mask, coregs, coupling maps overlain, skip first-pass results unless I include option to only do first-pass irfret
% conclude with eog or other display tool to open jpegs I've included in the PESTICA distribution for comparison purposes
% finally also release a new tutorial

if (exist('pmuflag','var')==0)
  pmuflag=0;
end

[err,ainfo] = BrikInfo(ep2d_filename);
tdim = ainfo.TAXIS_NUMS(1);
zdim = ainfo.DATASET_DIMENSIONS(3);
TR = ainfo.TAXIS_FLOATS(2);
[TRsec TRms] = TRtimeunitcheck(TR);
disp(sprintf('using %d slices, TR=%f seconds',zdim,TRsec));

if (pmuflag==1) 
  load RetroTS.PMU.mat
else
  load RetroTS.PESTICA5.mat
end

disp(sprintf('Mean Cardiac Rate: %f +/- %f',  mean(1./CARD.prd), std(1./CARD.prd)))  ;
disp(sprintf('Mean Respiratory Rate: %f +/- %f', mean(1./RESP.prd), std(1./RESP.prd)))  ;

h = figure('visible','off');
subplot(2,2,1);
hist(60./(diff(CARD.tptrace)),15)
COV_card = floor(100*std(diff(CARD.tptrace))/mean(diff(CARD.tptrace)))/100;
set(gca,'fontsize',16)
ylabel('Count');
xlabel('Card BPM');
title(['COV=' num2str(COV_card) ]);
subplot(2,2,3);
hist(60./(diff(RESP.tptrace)),15)
COV_resp = floor(100*std(diff(RESP.tptrace))/mean(diff(RESP.tptrace)))/100;
set(gca,'fontsize',16)
ylabel('Count');
xlabel('Resp BPM');
title(['COV=' num2str(COV_resp) ]);

subplot(2,2,2);
errorbar(CARD.hrfphz,CARD.hrf, CARD.hrfstd,'k','linewidth',2); 
SD_card = floor(100*mean(CARD.hrfstd))/100;
xlim([CARD.hrfphz(1)-0.5 CARD.hrfphz(end)+0.5]);ylim([-2 2]);
set(gca,'fontsize',16)
ylabel('A.U.'); % Arbitrary Units
xlabel('Card Res function in Cycle');
title(['SD=' num2str(SD_card) ]);
subplot(2,2,4);
errorbar(RESP.hrfphz,RESP.hrf, CARD.hrfstd,'k','linewidth',2)
SD_resp = floor(100*mean(RESP.hrfstd))/100;
xlim([RESP.hrfphz(1)-0.5 RESP.hrfphz(end)+0.5]);ylim([-2 2]);
set(gca,'fontsize',16)
ylabel('A.U.');
xlabel('Resp Res fuction in Cycle');
title(['SD=' num2str(SD_resp) ]);
