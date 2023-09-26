function slicedata=convert_timeseries_to_slicextime(tdata,slice_acq_order)

zdim = length(slice_acq_order);
if mod(length(tdata),zdim)
  disp('Error; timeseries should be a multiplication of slice acq vector term');
  return
end

tdim = length(tdata)/zdim;
slicedata = zeros(zdim,tdim);
tx = 1:zdim*tdim;
for z = 1:zdim
  slicedata(slice_acq_order(z),:) = tdata(z:zdim:zdim*tdim);
end