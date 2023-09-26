function ima_errt = polyfit3d(ima,np)

if ~exist('np','var')
  np=1;
end

simdim=size(ima);
N=length(ima(:));
tdim=simdim(end);

ima = reshape(ima,[N/tdim tdim]);

if np > 1
  ima_errt = zeros([N/tdim tdim]);
  for n = 1:N/tdim
    vox = ima(n,:);
    P = polyfit(1:tdim,vox,np);
    ima_errt(n,:) = vox- polyval(P,1:tdim);
  end 
else % linear detrending
  ima_errt =  detrend(ima')';
end

ima_errt = reshape(ima_errt,simdim);
