#!/usr/bin/env octave

% Developed using GNU Octave, version 4.2.2
% Used packages: 1) signal v1.3.2
%                2) image  v2.6.2

% Load required packages
pkg load signal   % Contains functions: dct2, idct2
pkg load image    % Contains function: psnr


% Function definition
function print_usage()
	printf("USAGE: ./%s [OPTIONS]\n", program_name());
	printf("Available options:\n");
	printf("\t-h, --help             Display this information\n");
	printf("\t-s, --save-imgs        Save images\n");
endfunction	


% Save images option. Default value: False
% Can be altered using command-line arguments.
save_imgs = 0;

% Parse command-line arguments.
arg_list = argv();
for i = 1:nargin()
	if (strncmp(arg_list{i}, "--save-imgs", length("--save-imgs")) ||
			strncmp(arg_list{i}, "-s", length("-s")))
		save_imgs = 1;
	elseif (strncmp(arg_list{i}, "--help", length("--help")) ||
			strncmp(arg_list{i}, "-h", length("-h")))
		print_usage();
		return;
	else
		print_usage();
		return;
	endif
endfor

f = imread('cameraman.tif');   % Read image as a matrix
F = dct2(f);  % Conduct a 2D Discrete Cosinte Transform in image f
F_orig = F;   % Create a copy of matrix F. Will be used to count how many cells were
              % set to zero during thresholding; it is faster than using a for-loop.

exec = 0;
THRESHOLDS = [5, 10, 20];
for threshold = THRESHOLDS
	printf("#################### Execution %d/%d ####################\n",
			++exec, size(THRESHOLDS)(2));
	printf("Threshold = %d\n", threshold);

	F(abs(F) < threshold) = [0];      % if |F(u,v)| < threshold then set F(u,v) to zero
	zeroed = sum(F(:) != F_orig(:));  % Compare matrices F and F_orig
	printf("Elements set to zero = %d\n", zeroed);

	I = idct2(F);   % Conduct a 2D Inverse Discrete Cosine Transform in image F
	i = uint8(I);   % Convert image I to unsigned 8-bit integer type

	% The following two lines seem redundant but it's better to be safe than sorry
	i(i < 0) = [0];      % Make sure no negative values exist in image i
	i(i > 255) = [255];  % Make sure no values greater that 255 exist in image i

	diff = sum(i(:) != f(:));  % Find how many pixels differ between images f and i
	same = size(f(:))(1);      % Find image size of f (matches size of image i)
	printf("Pixels that differ: %d/%d\n", diff, same);

	peaksnr = psnr(i, f);   % Calculate Peak Signal-to-noise Ratio
	printf("PSNR = %.4f dB\n\n", peaksnr);

	#{
	colormap(gray); imagesc(i)
	pause(3);
	#}
	
	% Save image i in PNG format (lossless) if required
	if (save_imgs)
		filename = sprintf("part1_thr%02d.png", threshold);
		printf("Saving %s...\n\n", filename);
		imwrite(i, filename);
	endif
endfor


