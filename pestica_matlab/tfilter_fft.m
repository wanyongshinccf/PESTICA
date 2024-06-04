function a=tfilter_fft(timeseries,cutoff);
 
% routine to apply a window filter to a 4D sdt file
% Author: M. Lowe
% Date: 19-JUL-2006

% input: file filename
% cutoff highest frequency bin to pass (as percentage of bin number!)
% calculate as 1/(samp rate/tdim/cutoff freq)
% Note that the tdim must be a power of two for this to work properly.
% Discard the first four volumes prior to filtering.

%cutoff=input('input cutoff highest freq bin to pass (bin number, calculate as 1/(samp rate/tdim/cutoff freq))');
tdim=length(timeseries);
fft_pow=floor(log(tdim*1.)/log(2.)+0.99999);
fft_dim=2^fft_pow;
 
fft_timeseries=fft(timeseries,[]);
% multiply by tdim to give bin number
cutoff=tdim*cutoff;
fft_timeseries([floor(cutoff)+1:tdim-floor(cutoff)])=0;
%a=abs(ifft(fft_timeseries,fft_dim));
a=real(ifft(fft_timeseries,[]));
 
