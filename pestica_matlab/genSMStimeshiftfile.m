function Tshift = genSMStimeshiftfile(MBfac, Nsli, TR, tpattern, pacetime)
% to generate time stamp 1D file of SMS acquisition.
% example
% run genSMStimeshiftfile(MBfac, Nsli, TR) using a matlab;
% run afni command to generate nifti file
% to3d -epan -time:zt 72 420 800 @tshiftfile_ms.1D -prefix <epi file name> 

if ~exist('tpattern')
  tpattern = 'alt+z';
end

if ~exist('pacetime')
  pacetime = 0 ;
end

if round(Nsli/MBfac) ~= Nsli/MBfac
  disp('Error: Slice number should be multiplication of MB acceleration factor');
  return
else
  mbslc = Nsli/MBfac;
end

if TR > 5 % sec
  disp(['TR = ' num2str(TR) 'ms'])
  TRms = TR;
else
  disp(['TR = ' num2str(1000*TR) 'ms'])
  TRms = 1000*TR;
end

if strcmp(tpattern,'asc')
  sliacqorder = 0:1:mbslc-1;
elseif strcmp(tpattern,'des')
  sliacqorder = mbslc-1:-1:0;
elseif strcmp(tpattern,'alt+z')
  if MBfac > 1 
    % new MB interleaved pattern
    if (mbslc > 6) && (mod(mbslc,2)==0)
      ninc =  mbslc/2 - 1;
      if mod(ninc,2) == 0
        ninc = ninc - 1;
      end
    else
      ninc = 2;
    end
    
    if (mbslc < 8)  && (mod(mbslc,2)==0) % if mbslc = 2, 4 or 6
      sliacqorder = [0:2:mbslc-1 1:2:mbslc-1];
    else
      n=1;
      sliacqorder=0;
      while n < mbslc
        n = n + 1;
        sliacqorder(n)= mod(sliacqorder(n-1)+ninc,mbslc);
      end
    end
  else % single band case
    if mod(mbslc,2) % if mbslc is odd
      sliacqorder = [0:2:mbslc-1 1:2:mbslc-1];
    else % if mbslc is even
      sliacqorder = [1:2:mbslc-1 0:2:mbslc-1];
    end 
  end
end

[sortedacqorder tshift] = sort(sliacqorder);
tshift=round((tshift-1)*(TRms-pacetime)/mbslc);

mbfac=1;
Tshift = tshift;
while mbfac < MBfac
  Tshift = [Tshift tshift];
  mbfac = mbfac + 1;
end

fp=fopen('tshiftfile_ms.1D','w'); 
fprintf(fp,'%g\n',Tshift); 
fp=fopen('tshiftfile_sec.1D','w'); 
fprintf(fp,'%g\n',Tshift/1000); 
fclose(fp);
