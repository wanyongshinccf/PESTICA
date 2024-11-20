function [SN RESP CARD] =run_RetroTS(ep2d_filename,cardfname,respfname,physioflag);

% function [SN RESP CARD] =run_RetroTS(ep2d_filename,cardfname,respfname,physioflag);
% run modifed RetroTS.m, provided by NIH/AFNI
% physioflag should be "PESTICA" or "PMU"
%   In case of PMU, RetroTS_CCF.m is called 
%   in case of PESTICA, RetroTS_CCF_PESTICA.m is called
%
% Initialized by Wanyong Shin, CCF, 20241114


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

Opts.ShowGraphs   = 0; 
Opts.VolTR        = ainfo.TAXIS_FLOATS(2); 
Opts.Nslices      = zdim; 
if exist('tshiftfile.1D')
  Opts.SliceOffset  = load('tshiftfile.1D');
  disp('Slice acquistion timing info is read from tshiftfile.1D')
else
  Opts.SliceOffset  = ainfo.TAXIS_OFFSETS;
  disp('Slice acquistion timing info is read from the header')
end
Opts.SliceOrder   = 'Custom';
Opts.PhysFS       = samplingrate; 
Opts.Quiet        = 1; 
Opts.RVT_out      = 0; % note no RVT here, feel free to modify it

% copy Card and Resp options without card/resp file name
CardOpts = Opts;
RespOpts = Opts;

% save Respiratory signals
if sum(std(resp_raw)) ~= 0
  % save RetroTS.Resp.slicebase.1D here
  RespOpts.Prefix       = ['RetroTS.' physioflag  '.resp'];
  RespOpts.Respfile     = respfname;
  if strcmp(physioflag,'PMU')
    [SN, RESP, CARD] = RetroTS_CCF(RespOpts);
  else % PESTICA
    [SN, RESP, CARD] = RetroTS_CCF_PESTICA(RespOpts);
  end

  % register resp file for full RETROICOR 
  Opts.Respfile     = respfname;

end

if sum(std(card_raw)) ~= 0
  % save RetroTS.Card.slicebase.1D here
  CardOpts.Prefix       = ['RetroTS.' physioflag '.card'];
  CardOpts.Cardfile     = cardfname;
  [SN, RESP, CARD] = RetroTS_CCF(CardOpts);
 
  % register card file for full RETROICOR
  Opts.Cardfile     = cardfname;
end

% save RetroTS.PMU.slicebase.1D
Opts.Prefix       = ['RetroTS.' physioflag ];
if strcmp(physioflag,'PMU')
  [SN, RESP, CARD] = RetroTS_CCF(Opts);
else
  [SN, RESP, CARD] = RetroTS_CCF_PESTICA(Opts);
end




% The below is to generate resp/card phase function
% See Shin, Koening and Lowe, Neuroimage 2022
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
  subplot(2,3,1); plot(CARD.t,CARD.v); xlim([0 30]); 
  title('Card signal (< 30s)')
  text(5,-1000,sprintf('null pt = %6d',length(find(card_raw==0))))
  text(5,-1500,sprintf('sat pt = %6d',length(find(card_raw==4095))))
  
  subplot(2,3,2); errorbar(1:100,mean(cardRF,1),std(cardRF,1));xlim([0 100]);title('Card cycle');
  text(30,-1, sprintf('SD = %3.2f', mean(std(cardRF))));
  
  subplot(2,3,3);hist((CARD.prd),30)
  title(sprintf('Card period: %3.1f +/- %3.1f', mean(CARD.prd), std(CARD.prd)))
  ylabel('Count'); xlabel('seconds'); 
  
end

if sum(std(resp_raw)) ~= 0
  subplot(2,3,4); plot(RESP.t,RESP.v); xlim([0 60]); 
  title('Resp signal (<1min)')
  text(5,-1000,sprintf('null pt = %6d',length(find(resp_raw==0))))
  text(5,-1500,sprintf('sat pt = %6d',length(find(resp_raw==4095))))

  subplot(2,3,5); errorbar(1:100,mean(respRF,1),std(respRF,1));xlim([0 100]);title('Resp cycle')
  text(30,-1, sprintf('SD = %3.2f', mean(std(respRF))));ylim([-2 2])

  subplot(2,3,6);hist((RESP.prd),30)
  title(sprintf('Resp period: %3.1f +/- %3.1f', mean(RESP.prd), std(RESP.prd)))
  ylabel('Count'); xlabel('seconds'); 
end
saveas(gcf,[ physioflag '_qualtiycheck.png']);
  
save(['RetroTS.' physioflag '.mat'],'SN','RESP','CARD');
