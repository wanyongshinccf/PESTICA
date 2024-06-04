function [SN RESP CARD] = RetroTS_CCF_adv(ep2d_filename,cardfname,respfname);

% if ~exist('ep2d_filename')
%   ep2d_filename='S40vol+orig';
% end
% if ~exist('mask_filename')
%   mask_filename='S40vol.brain+orig';
% end
% if ~exist('cardfname')
%   cardfname='card_raw_pmu.dat';
% end
% if ~exist('respfname')
%   respfname='resp_raw_pmu.dat';
% end

[err,ainfo] = BrikInfo(ep2d_filename);
tdim = ainfo.TAXIS_NUMS(1);
zdim = ainfo.DATASET_DIMENSIONS(3);
TR = ainfo.TAXIS_FLOATS(2);
[TRsec TRms] = TRtimeunitcheck(TR);

resp1d = load(respfname);
samplingrate = length(resp1d)/TRsec/tdim;

% calculate phase using RetroTS,
SN.Respfile=respfname;
SN.Cardfile=cardfname;
SN.ShowGraphs = 0; 
SN.VolTR = ainfo.TAXIS_FLOATS(2); 
SN.Nslices = ainfo.TAXIS_NUMS(2); 
SN.SliceOffset=ainfo.TAXIS_OFFSETS;
SN.SliceOrder='Custom';
SN.PhysFS = samplingrate; 
SN.Quiet=1; 
SN.Prefix=['RetroTSpmu'];
[SN, RESP, CARD] = RetroTS_ccf(SN);
h = figure('visible','off');
subplot(4,1,1); plot(RESP.t,RESP.v);title('Respiratory signal')
subplot(4,1,2); plot(RESP.t,RESP.v); xlim([0 60]);
subplot(4,1,3); plot(CARD.t,CARD.v);title('Cardiac signal')
subplot(4,1,4); plot(CARD.t,CARD.v); xlim([0 60]);
saveas(gcf,'pmu_qualtiycheck.png');

disp(sprintf('Mean Cardiac Rate (BPM): %f, Mean Respiratory Rate (BPM): %f',60*length(CARD.prd)/CARD.t(end),60*length(RESP.prd)/RESP.t(end)))  ;
h = figure('visible','off');
subplot(2,1,1);
hist(60./(diff(CARD.tptrace)),15)
set(gca,'fontsize',16)
ylabel('Count');
xlabel('Beats per Minute');
subplot(2,1,2);
hist(60./(diff(RESP.tptrace)),15)
set(gca,'fontsize',16)
ylabel('Count');
xlabel('Breaths per Minute');
saveas(gcf,'pmu_qa_hists.png');
  
save(['RetroTSpmu.mat'],'SN','RESP','CARD');