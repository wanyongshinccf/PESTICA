function prepare_ICA_decomp_polort(comps,ep2d_filename,mask_filename,tdim_skip,ext_option)
%
% function prepare_ICA_decomp_polort(comps,ep2d_filename,mask_filename,tdim_skip,ext_option)
%
% Note that this function is modified from prepare_ICA_decomp function. 
% Only difference from the origianl function is, input is already
% detrended (polynomial fitting) data.
%
% comps=give the number of components in the decomposition 
% (10-15 are robust for 4mm and 2mm voxels)
% ep2d_filename=NIFTI or AFNI format file containing 4D ep2d data
% OPTIONAL mask_filename=NIFTI or AFNI format containing 3D mask data for ep2d_filename
% OPTIONAL tdim_skip=numbers of initial volumes to skip (default 0) to avoid initial SSFP effect
% OPTIONAL ext_option=1 or 0 to switch on or off extended infomax algorithm
%
% this function assumes that the input data specified by ep2d_filename is a 4D
% ep2d timeseries fMRI data with slice as the 3rd dimension and volume
% as the fourth dimension.  If this is not correct, permute your dataset
% so this assumption is correct (the IC's are only used to compute physiologic
% noise, which requires the slice as 3rd dim and the data are ep2d)
%
% size of imaging matrix may become problematic, as 128x128 matrix slices are 
% very time-consuming and MATLAB may run out of memory (TODO: modify to use memory mapping)
% modify poolsize in PESTICA setup script.

if (exist('comps','var')==0 | exist('ep2d_filename','var')==0)
  disp('must input two parameters: number of components, and filename of EPI data');
  disp('     third optional paramter = ANALYZE format 3D mask file for EPI data');
  disp('     fourth optional paramter = 1 for extended form of infomax ICA');
  return;
end
if (exist('ext_option','var')==0)
  ext_option=0;
end
if (exist('tdim_skip','var')==0)
  tdim_skip=0;
end

% read images
Opt.Format = 'matrix';
[err, ima, ainfo, ErrMessage]=BrikLoad(ep2d_filename, Opt);
xdim=ainfo.DATASET_DIMENSIONS(1);
ydim=ainfo.DATASET_DIMENSIONS(2);
zdim=ainfo.DATASET_DIMENSIONS(3);
tdim=ainfo.DATASET_RANK(2);
if (tdim<50)
  disp('small temporal dimension, not recommended');
end

% read mask
[err,mask,minfo,ErrMessage]=BrikLoad(mask_filename, Opt);
mask(find(mask~=0))=1;
ima=reshape(ima,[xdim*ydim zdim tdim]);
mask=reshape(mask,[xdim*ydim zdim]);
ima=ima(:,:,tdim_skip+1:end);
tdim=tdim-tdim_skip;

homedir=pwd;
disp(sprintf('Starting slicewise temporal ICA on %d slices, with %d components each',zdim,comps));
disp('Slices with many voxels (esp middle of brain if 2x2mm) take time to decompose...');
tic
for z=1:zdim
  tfile=sprintf('pestica5_%dcomps_slice%d.mat',comps,z);
  % test for existence of ICA-decomposed .mat file
  if (exist(tfile,'file')==2)
    disp(['Skip: ' tfile ' exists'])
  else
  
    slicedata=double(reshape(squeeze(ima(:,z,:)),[xdim*ydim tdim]));
    % reduce dimensionality with mask(:,:,z), save a matrix for converting back at the end
    q=0;
    clear reduced_slicedata convertback;
    indices=find(mask(:,z)==1);
    reduced_slicedata=slicedata(indices,:);
    if (length(indices)<5*comps)
      disp(sprintf('none (or not enough: %d) tissue voxels on this slice, skipping...',q));
      continue;
    end
    % run temporal ICA on data, running PCA first and keeping 10 principal components to pass to ICA
    % running linear detrend first, removing mean also
    
    if (ext_option==0)
      [w,s]=runica(reduced_slicedata,'pca',comps,'verbose','off');
    else
      [w,s]=runica(reduced_slicedata,'pca',comps,'extended',1,'verbose','off');
    end
    u=w*s; % unmixed matrix
    m=pinv(u);
    A=u*reduced_slicedata;
    % convert back to full spatial dimension
    converted_m=zeros(size(slicedata,1),size(m,2));
    converted_m(indices,:)=m;
    disp(sprintf('done with slice %d',z));
    m=converted_m;
    save(tfile,'z','w','A','m');
    %save(sprintf('pestica_%dcomps_slice%d.mat',comps,z),'z','w','s','A','m');
    clear w s A converted_m;
  end
end
toc