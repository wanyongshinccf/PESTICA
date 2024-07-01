function retroicor_pestica(ep2d_filename,cardfname,respfname,mask_filename,polortMat)
% function retroicor_pestica(ep2d_filename,card,resp,M,slice_timing,mask_filename,buckettemplate,flag_D)
% Wanyong Shin 2017/03/31
% 
% This function performs the physiological noise correction from PESTICA5
%
% input 
%   ep2d_filename: epi file without moco & slice time shift
%   card : the estimated cardiac noise with zdim/TR sampling rate
%   resp : the estimated respiratory noise with zdim/TR sampling rate
%   mask_filename: skull removed mask or image
%   buckettemplate: template to store statistical AFNI format
%
% output: 
%   *.retroicor_pestica5: physio noise is removed from ep2d_file
%   *.retroicor_pestica5.bucket: 
%     [0]: F test of whole model 
%     [1]: (stepwise) F test of respiratory signal model (comp=5)
%     [2]: (stepwise) F test of cardiac signal model (comp=3)
%     [3,5,..]: coefficients of 8 components (first 5: resp, last 3: card) 
%     [4,6,..]: t-score of 8 components (first 5: resp, last 3: card)
%

% define bucket template
strpath = which('retroicor_pestica');
retroicordir = strpath(1:strfind(strpath,'/retroicor_pestica'));
buckettemplate = [retroicordir '/retroicor_pestica.bucket+orig'];

%
Opt.Format = 'matrix';
[err, ima, ainfo, ErrMessage]=BrikLoad(ep2d_filename, Opt);
xdim=ainfo.DATASET_DIMENSIONS(1);
ydim=ainfo.DATASET_DIMENSIONS(2);
zdim=ainfo.DATASET_DIMENSIONS(3);
tdim=ainfo.DATASET_RANK(2);
TR=1000*double(ainfo.TAXIS_FLOATS(2));
[TRsec TRms] = TRtimeunitcheck(TR);

if (exist('mask_filename','var')~=0)
  [err,mask,minfo,ErrMessage]=BrikLoad(mask_filename, Opt);
  mask = mask(:,:,:,1);  mask(find(mask~=0))=1;
else
  mask=ones(xdim,ydim,zdim);
end

card = load(cardfname); 
resp = load(respfname);

card = card./std(card);
resp = resp./std(resp);

% read polinomial signal drift vectors
polort_reg = load(polortMat);

slice_timing_sec = load('tshiftfile.1D');
[MBacc zmbdim uniq_slice_timing_sec uniq_acq_order] = SMSacqcheck(TRsec, zdim, slice_timing_sec);

% pestica5 add on
samplingrate = length(card)/TRsec/tdim;

% calculate phase using RetroTS,
% note that input is not PMU, but estimated Nslices/TR sampling rate of 
% singal fluctuation, REFLECTED ON EPI

SN=[];
SN.Cardfile     = cardfname;
SN.Respfile     = respfname;
SN.ShowGraphs   = 0; 
SN.VolTR        = TRsec; 
SN.Nslices      = zdim; 
SN.SliceOffset  = slice_timing_sec;
SN.SliceOrder   = 'Custom';
SN.PhysFS       = samplingrate; 
SN.Quiet=1; 
SN.Prefix=['RetroTS.PESTICA5']; 
SN.RVT_out      = 0;
[SN, RESP, CARD] = RetroTS_CCF_pestica(SN);

tmap = zeros(xdim,ydim,zdim,4+1);
bmap = zeros(xdim,ydim,zdim,4+1);
fmap = zeros(xdim,ydim,zdim,3);
rmap = zeros(xdim,ydim,zdim,4);
errtmap = zeros(xdim,ydim,zdim,tdim);

disp(['Voxelwise PESTICA RETROICOR is running'])
tic
Ap = polort_reg;
for z= 1:zdim
  
  Ar = [RESP.slc_reg(:,z) polort_reg];
  Ac = [squeeze(CARD.phz_slc_reg(:,1:4,z)) polort_reg];  
  A  = [RESP.slc_reg(:,z) squeeze(CARD.phz_slc_reg(:,1:4,z)) polort_reg];
  
  for x=1:xdim
    for y=1:ydim
      if mask(x,y,z)
        % detrending, normalizing
        errt =squeeze(ima(x,y,z,:));
        SD=std(errt);
        errt_norm = errt/SD;
        
        % solve linear regression
        [p, std_err] = lscov(A, errt_norm);
        res = errt_norm - (A*p);    RSS = res'*res;
       
        % regress out physiologic noise & trending, but keep the contrast
        p(6) = 0; 
        errt_errt = errt_norm - (A*p);
        errtmap(x,y,z,:) = errt_errt*SD;
        
        bmap(x,y,z,:) = p(1:5);
        tmap(x,y,z,:) = p(1:5)./std_err(1:5);
        
        % additioanl F values for cardiac and respiratory regressors
        [pp,std_err] = lscov(Ap, errt_norm);
        res = errt_norm - Ap*pp;      RSSp = res'*res;
        [pr,std_err] = lscov(Ar, errt_norm);
        res = errt_norm - Ar*pr;      RSSr = res'*res;
        [pc,std_err] = lscov(Ac, errt_norm);
        res = errt_norm - Ac*pc;      RSSc = res'*res;
                
        % F-test
        % F = {(RSS1 - RSS2)/(p2-p1)} / { RSS2/(n-p2) }
        % Model1: the restricted model 
        % Model2: the unrestricted (full) model
        % the variables (regressors) that are not included in Model1 are
        % our intesest to see how big chagne between RSS1 and RSS2
        % RSS1,2: residual sum of squres model1 or 2
        % p1,2  : number of regressor of model1 or 2 (p2 > p1)
        % n     : data point, here tdim
        fmap(x,y,z,1:3) = [(RSSp-RSS)/RSS*(tdim-size(A,2))/5 ...
                           (RSSc-RSS)/RSS*(tdim-size(A,2))/1 ...
                           (RSSr-RSS)/RSS*(tdim-size(A,2))/4 ];
        rmap(x,y,z,1:4) = [RSS RSSr RSSc RSSp].*SD^2;                    
      end
    end
  end
  if z==1
    fprintf('slice1.') 
  elseif z == zdim
    fprintf([num2str(zdim) '\n'])
  else
    fprintf('.')   
  end
end
disp('PESTICA5 is done')
toc

bucket               = zeros(xdim,ydim,zdim,13);
bucket(:,:,:,1:3)    = fmap;
bucket(:,:,:,4:2:12) = bmap;
bucket(:,:,:,5:2:13) = tmap;

% keep same format as input data
ainfo.BRICK_TYPES=3*ones(1,tdim); % 1=short, 3=float
ainfo.BRICK_STATS = []; %automatically set
ainfo.BRICK_FLOAT_FACS = [];%automatically set
ainfo.BRICK_LABS = [];
ainfo.BRICK_KEYWORDS = [];
OptOut.Scale = 0;
OptOut.OverWrite= 'y';
OptOut.verbose = 0;
OptOut.Prefix = [ep2d_filename(1:strfind(ep2d_filename,'+')-1) '.retroicor_pestica'];  
[err,ErrMessage,InfoOut]=WriteBrik(errtmap,ainfo,OptOut);

% generated bucket files
[err,binfo] = BrikInfo(buckettemplate);
binfo.DATASET_DIMENSIONS(1:3) = ainfo.DATASET_DIMENSIONS(1:3);
binfo.DELTA = ainfo.DELTA;
binfo.IJK_TO_DICOM_REAL = ainfo.IJK_TO_DICOM_REAL;
binfo.Orientation = ainfo.Orientation;
binfo.ORIGIN = ainfo.ORIGIN; 
OptOut.Scale = 0;
OptOut.OverWrite= 'y';
OptOut.verbose = 0;
binfo.BRICK_LABS='Full_Fstat~Resp_Fstst~Card_Fstst';
binfo.BRICK_LABS=[binfo.BRICK_LABS '~Resp_Coef~Resp_Tstat~CardSin#0_Coef~CardSin#0_Tstat~CardCos#0_Coef~CardCos#0_Tstat~CardSin#1_Coef~CardSin#1_Tstat~CardCos#1_Coef~CardCos#1_Tstat'];
binfo.BRICK_STATAUX = [0 4 2 5 (tdim-size(A,2)) 1 4 2 1 (tdim-size(A,2)) 2 4 2 4 (tdim-size(A,2))...
                       4 3 1 (tdim-size(A,2)) 6 3 1 (tdim-size(A,2))  8 3 1 (tdim-size(A,2)) ...
                       10 3 1 (tdim-size(A,2)) 12 3 1 (tdim-size(A,2)) ];
OptOut.Prefix = [ep2d_filename(1:strfind(ep2d_filename,'+')-1) '.retroicor_pestica.bucket'];  
[err,ErrMessage,InfoOut]=WriteBrik(bucket,binfo,OptOut);

% below is for the calculation of residual sum of squares in each model.
% used for cPESTICA paper. you won't need it.
pesticaQAflag =0;
if pesticaQAflag
  % keep same format as input data
  binfo.BRICK_TYPES=3*ones(1,4); % 1=short, 3=float 
  binfo.BRICK_LABS=['RSS~RSSr~RSSc~RSSp'];
  OptOut.Prefix = [ep2d_filename(1:strfind(ep2d_filename,'+')-1) '.retroicor_pestica.RSS'];  
  [err,ErrMessage,InfoOut]=WriteBrik(rmap,binfo,OptOut);
end
