function [fext,fcard,fresp] = readpmuxa(pmufileprefix,TR)

% test purpose
extfn='Style_EXT1_myPhysio.txt';
cardfn='Style_PULS_myPhysio.txt';
respfn='Style_RESP_myPhysio.txt';

[filepath, pname, ext] = fileparts([pmufileprefix '.xml']);   
extfn  = [filepath '/Style_EXT1_' pname '.txt' ];
cardfn = [filepath '/Style_PULS_' pname '.txt' ];
respfn = [filepath '/Style_RESP_' pname '.txt' ];

if ~exist( 'DSrate' );
    DSrate = 50;
end

% read files
ext  = readmatrix(extfn);
resp = readmatrix(respfn);
card = readmatrix(cardfn);

ttable_ext = ext(:,1);
ttable_card = card(:,1);
ttable_resp = resp(:,1);
sig_ext=ext(:,2);
sig_card = card(:,2);
sig_resp = resp(:,2);

% set trigger point of the first points among trigger block
tdim = length(find(diff(sig_ext)== -1));

% SR_ext = 1000/(ext(2,1)-ext(1,1)); % 1000Hz
% SR_card = 1000/(card(2,1)-card(1,1)); % 500Hz
% SR_resp = 1000/(resp(2,1)-resp(1,1)); % 125Hz
SR_ext = 400; tp_ext=2.5;
SR_card = 200;tp_card=5;
SR_resp = 50; tp_resp=40;

% tp_starts, tp_ends
tp_starts = ttable_ext(1);
tp_ends  = tp_starts + 1000*TR*tdim/tp_ext -1;

ttable_ext_ext  = tp_starts:tp_ends-1*tp_ext;
ttable_card_ext = tp_starts:tp_card/tp_ext:tp_ends-1*tp_card;
ttable_resp_ext = tp_starts:tp_resp/tp_ext:tp_ends-1*tp_resp;

sig_ext_ext = sig_ext(find(ttable_card==tp_starts):end);
sig_ext_ext(length(sig_ext_ext)+1:length(ttable_ext_ext))=0;

sig_card_ext = sig_card(find(ttable_card==tp_starts):end);
sig_card_ext(length(sig_card_ext)+1:length(ttable_card_ext))=mean(sig_card);
sig_resp_ext = sig_resp(find(ttable_resp==tp_starts):end);
sig_resp_ext(length(sig_resp_ext)+1:length(ttable_resp_ext))=mean(sig_resp);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% downsampl, if necesary %
%%%%%%%%%%%%%%%%%%%%%%%%%%
if SR_ext ~= DSrate
  disp(['fext is downsamled with ' num2str(DSrate) 'Hz.'])
end

fext  = sig_ext_ext(1:SR_ext/DSrate:end);
fcard = sig_card_ext(1:SR_card/DSrate:end);
fresp = sig_resp_ext(1:SR_resp/DSrate:end);
