function [SN RESP CARD] = RetroTS_CCF_run(ep2d_filename,cardfname,respfname);

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

card_raw = load(cardfname);
resp_raw = load(respfname);
samplingrate = length(resp_raw)/TRsec/tdim;

% calculate phase using RetroTS,
if sum(std(resp_raw)) ~= 0
  SN.Respfile     = respfname;
end
if sum(std(card_raw)) ~= 0
  SN.Cardfile     = cardfname;
end
SN.ShowGraphs   = 0; 
SN.VolTR        = ainfo.TAXIS_FLOATS(2); 
SN.Nslices      = zdim; 
if exist('tshiftfile.1D')
  SN.SliceOffset  = load('tshiftfile.1D');
  disp('Slice acquistion timing info is read from tshiftfile.1D')
else
  SN.SliceOffset  = ainfo.TAXIS_OFFSETS;
  disp('Slice acquistion timing info is read from the header')
end
SN.SliceOrder   = 'Custom';
SN.PhysFS       = samplingrate; 
SN.Quiet        = 1; 
SN.Prefix       = ['RetroTS.PMU'];
SN.RVT_out      = 0; % note no RVT here, feel free to modify it
[SN, RESP, CARD] = RetroTS_CCF(SN);

if sum(std(card_raw)) ~= 0
  cardRF = zeros(length(CARD.tntrace)-1,100);
  nstd = std(CARD.v);
  for n = 1:length(CARD.tntrace)-1
    sigincycle = CARD.v(find(CARD.t == CARD.tntrace(n)): find(CARD.t == CARD.tntrace(n+1)))./nstd;
    t = 0:1000/length(sigincycle):1000;
    cardRF(n,:) = pchip(t(2:end),sigincycle',10:10:1000);
  end
end

if sum(std(resp_raw)) ~= 0
  respRF = zeros(length(RESP.tntrace)-1,100);
  nstd = std(RESP.v);
  for n = 1:length(RESP.tntrace)-1
    sigincycle = RESP.v(find(RESP.t == RESP.tntrace(n)): find(RESP.t == RESP.tntrace(n+1)))./nstd;
    t = 0:1000/length(sigincycle):1000;
    respRF(n,:) = pchip(t(2:end),sigincycle',10:10:1000);
  end
end

h = figure('visible','off');

if sum(std(card_raw)) ~= 0
  subplot(2,3,1); plot(CARD.t,CARD.v); xlim([0 30]); ylim([-2000 2000])
  title('Card signal (< 30s)')
  text(5,-1000,sprintf('null pt = %6d',length(find(card_raw==0))))
  text(5,-1500,sprintf('sat pt = %6d',length(find(card_raw==4095))))
  
  subplot(2,3,2); errorbar(1:100,mean(cardRF,1),std(cardRF,1));xlim([0 100]);title('Card cycle');
  text(30,-1, sprintf('SD = %3.2f', mean(std(cardRF))));ylim([-2 2])
  
  subplot(2,3,3);hist((CARD.prd),30)
  title(sprintf('Card period: %3.1f +/- %3.1f', mean(CARD.prd), std(CARD.prd)))
  ylabel('Count'); xlabel('seconds'); ylim([0 10])
  
end

if sum(std(resp_raw)) ~= 0
  subplot(2,3,4); plot(RESP.t,RESP.v); xlim([0 60]); ylim([-2000 2000])
  title('Resp signal (<1min)')
  text(5,-1000,sprintf('null pt = %6d',length(find(resp_raw==0))))
  text(5,-1500,sprintf('sat pt = %6d',length(find(resp_raw==4095))))

  subplot(2,3,5); errorbar(1:100,mean(respRF,1),std(respRF,1));xlim([0 100]);title('Resp cycle')
  text(30,-1, sprintf('SD = %3.2f', mean(std(respRF))));ylim([-2 2])

  subplot(2,3,6);hist((RESP.prd),30)
  title(sprintf('Resp period: %3.1f +/- %3.1f', mean(RESP.prd), std(RESP.prd)))
  ylabel('Count'); xlabel('seconds'); ylim([0 10])
end
saveas(gcf,'pmu_qualtiycheck.png');
  
save(['RetroTS.PMU.mat'],'SN','RESP','CARD');
