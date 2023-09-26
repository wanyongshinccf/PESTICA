function tdata_est=convert_slicextime_to_timeseries(slicedata,slice_acq_order,keep_slices)

zdim = size(slicedata,1);
tdim = size(slicedata,2);
if (zdim ~= length(slice_acq_order))
  disp('Error; slice data does not match slice acq order vector');
  return
end

if ~exist('keep_slices')
  keep_slices = ones(1,zdim);
end

tdata = zeros(1,zdim*tdim);
ttable = 1:zdim*tdim;
ttable_keep_slices = zeros(1,zdim*tdim);
for z = 1:zdim
  if keep_slices(slice_acq_order(z))
    tdata(z:zdim:zdim*tdim) = slicedata(slice_acq_order(z),:);
    ttable_keep_slices(z:zdim:zdim*tdim)=ttable(z:zdim:zdim*tdim);
  end
end

% interpolate here
if sum(keep_slices) ~= zdim
  ttable_nonzero = ttable;
  tdata_nonzero  = tdata;
  ttable_nonzero(find(ttable_keep_slices==0))=[];
  tdata_nonzero(find(ttable_keep_slices==0))=[];
  
  if ttable_nonzero(end) ~= ttable(end)
    ttable_nonzero = [ttable_nonzero ttable(end)]; 
    tdata_nonzero = [tdata_nonzero tdata_nonzero(end)]; 
  end
  if ttable_nonzero(1) ~= ttable(1)
    ttable_nonzero = [0 ttable_nonzero]; 
    tdata_nonzero = [tdata_nonzero(1) tdata_nonzero]; 
  end
  
  tdata_est = pchip(ttable_nonzero,tdata_nonzero,ttable);
else
  tdata_est = tdata; 
end
