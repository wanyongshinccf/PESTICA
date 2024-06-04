function [MBacc zmbdim uniq_slice_timing_ms uniq_acq_order ] = SMSacqcheck(TRms, zdim, slice_timing_ms)


timegap_slice = TRms/zdim; % second unit
uniq_slice_timing_ms = unique(slice_timing_ms,'stable');
[uniq_sorted_slice_timing_ms uniq_acq_order] = sort(uniq_slice_timing_ms);

MBacc = length(find(slice_timing_ms==0));

if MBacc > 1
  disp(['Note: SMS acquisition is applied (MB acc. fac = ' num2str(MBacc) ').'])
elseif MBacc == 1
  disp(['Note: no SMS accelration is applied.'])
else
  disp ('Error: no slice timing at zero')
  return
end
zmbdim = zdim/MBacc;
