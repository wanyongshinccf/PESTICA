function Tshift = calcSMStimeshift(MBfac, Nsli, TR, tpattern, pacetime)
% to generate time stamp 1D file of SMS acquisition.
% example
% run genSMStimeshiftfile(MBfac, Nsli, TR) using a matlab;
% run afni command to generate nifti file
% to3d -epan -time:zt 72 420 800 @tshiftfile_ms.1D -prefix <epi file name> 

if ~exist('tpattern')
  tpattern = 'alt';
end

if ~exist('pacetime')
  pacetime = 0;
end

if round(Nsli/MBfac) ~= Nsli/MBfac
  disp('Error: Slice number should be multiplication of MB acceleration factor');
  return
else
  mbslc = Nsli/MBfac;
end

if strcmp(tpattern,'asc')
  sliacqorder = 0:1:mbslc-1;
elseif strcmp(tpattern,'des')
  sliacqorder = mbslc-1:-1:0;
elseif strcmp(tpattern,'alt')
  if mod(mbslc,2) % if mbslc is odd
    sliacqorder = [0:2:mbslc-1 1:2:mbslc-1];
  else % if mbslc is even
    sliacqorder = [1:2:mbslc-1 0:2:mbslc-1];
  end
end

[sortedacqorder tshift] = sort(sliacqorder);
tshift=(tshift-1)*(TR-pacetime)/mbslc;

mbfac=1;
Tshift = tshift;
while mbfac < MBfac
  Tshift = [Tshift tshift];
  mbfac = mbfac + 1;
end
