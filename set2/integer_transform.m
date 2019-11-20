function [W]= integer_transform(X)

% X is a 4x4 block of data
% W is the transformed coefficients


 % C is the core transform matrix
C =  [1 1 1 1
      2 1 -1 -2
      1 -1 -1 1
      1 -2 2 -1];

  W = (C*X*C');


end
