#!/usr/bin/env octave

pkg load signal % Package 'signal' contains the dct2() 

f = imread('cameraman.tif');   % Read image as a matrix
F = dct2(f);  % Conduct a 2D Discrete Cosinte Transform in image f
F_orig = F;   % Create a copy of matrix F

THRESHOLD = 5;
t1 = time();
F(abs(F) < THRESHOLD) = [0];   % if |F(u,v)| < THRESHOLD then set F(u,v) to zero
zeroed = sum(F(:) != F_orig(:));   % Compare matrices F and F_orig
t2 = time();
printf("Set %d elements to zero (%f sec)\n", zeroed, (t2 - t1));

I = idct2(F);
i = uint8(I);

i(i < 0) = [0];   % Make sure no negative values exist
i(i > 255) = [255];   % Make sure no values greater that 255 exist

#{
colormap(gray); imagesc(f)
pause(3);
printf("Showing second image\n");
colormap(gray); imagesc(i)
pause(3);
#}

diff = sum(i(:) != f(:));
same = size(f(:))(1);

printf("%d / %d pixels differ\n", diff, same);

