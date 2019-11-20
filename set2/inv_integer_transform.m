function [Y] = inv_integer_transform(W)


 % Ci is the inverse core transform matrix
Ci =  [1 1 1 1
      1 1/2 -1/2 -1
      1 -1 -1 1
      1/2 -1 1 -1/2];

 Y = Ci'*W*Ci;

end
