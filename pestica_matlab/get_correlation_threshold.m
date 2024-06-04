function threshold=get_correlation_threshold(searchpenalty,dof,significance)
% threshold=get_correlation_threshold(searchpenalty,dof,significance)
% based on following function for significance of a correlation coeff c:
%  sig=erfc(abs(0.5*log((1+c)/(1-c)))*sqrt((dof-3)/2.0))*searchpenalty
% search penalty is the number of concurrent tests, dof is degrees of freedom
% significance is optional, by default 3*sigma (or 0.0027 = 1-0.9973)
% relevant for two-sided significance

if(exist('significance')~=1)
  significance=0.0027;
end
searchpenalty=double(round(searchpenalty));
dof=round(dof);
if (dof<5)
  disp('no significance possible: number of data points MUST be greater than 4 for this slice');
  threshold=1.0;
  return
end

A=exp(erfcinv(significance/searchpenalty)*2*sqrt(2/(double(dof)-3)));
threshold=(A-1)/(A+1);


