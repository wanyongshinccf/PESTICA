function [bli, ble, num] = fftsegs (ww, po, nv)
% Returns the segements that are to be used for fft
% calculations.
%  ww: Segment width (in number of samples)
%  po: Percent segment overlap
%  nv: Total number of samples in original symbol
% Returns:
% bli, ble: Two Nblck x 1 vectors defining the segments'
%           starting and ending indices
% num: An nv x 1 vector containing the number of segments
%      each sample belongs to
%example
% [bli, ble, num] = fftsegs (100, 70, 1000);

   if (ww==0),
      po = 0;
      ww = nv;
   elseif (ww < 32 | ww > nv),
      fprintf(2,'Error fftsegs: Bad value for window width of %d\n', ww);
      return;
   end
   out = 0;
   while (out == 0),
      clear bli ble
      %How many blocks?
      jmp = floor((100-po)*ww/100); %jump from block to block
      nblck = nv./jmp;  %number of jumps

      ib = 1;
      cnt = 0;
      while (cnt < 1 | ble(cnt)< nv),
         cnt = cnt + 1;
         bli(cnt) = ib;
         ble(cnt) = min(ib+ww-1, nv);
         ib = ib + jmp;
      end
      %if the last block is too small, spread the love
      if (ble(cnt) - bli(cnt) < 0.1.*ww), % too small a last block, merge
         ble(cnt-1) = ble(cnt);           % into previous
         cnt = cnt -1;
         ble = ble(1:cnt); bli = bli(1:cnt);
         out = 1;
      elseif (ble(cnt) - bli(cnt) < 0.75.*ww), % too large to merge, spread it
         ww = ww+floor((ble(cnt)-bli(cnt))./nblck);
         out = 0;
      else %last block big enough, proceed
         out = 1;
      end
   %ble - bli + 1
   %out
   end
   %bli
   %ble
   %ble - bli + 1
   %now figure out the number of estimates each point of the time series gets
   num = zeros(nv,1);
   cnt = 1;
   while (cnt <= length(ble)),
      num(bli(cnt):ble(cnt)) = num(bli(cnt):ble(cnt))+ ones(ble(cnt)-bli(cnt)+1,1);
      cnt = cnt + 1;
   end
