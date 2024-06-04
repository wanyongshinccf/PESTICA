function Y=eeglab_sign(X)

if (exist('sign')==5)
  Y=sign(X);
  return
end

% elements of complex X are divided by absolute value
Y=X./abs(X);

% zero elements of X have zero valued sign
Y(find(X==0))=0;

