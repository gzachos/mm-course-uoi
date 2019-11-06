#!/usr/bin/env octave

% Developed using GNU Octave, version 4.2.2
% Used packages: 1) signal v1.3.2
%                2) image  v2.6.2

% Load required packages
pkg load signal   % Contains functions: dct2, idct2
pkg load image    % Contains function: psnr, entropy


% Function definition
function print_usage()
	printf("USAGE: ./%s [OPTIONS]\n", program_name());
	printf("Available options:\n");
	printf("\t-h, --help             Display this information\n");
	printf("\t-a, --use-absolute     Use absolute value to calculate the entropy of F-caret\n");
	printf("\t                       (Default: false - The minimum negative value is added to all elements)\n");
	printf("\t-m, --multiplier  M    Quantization matrix scalar multiplier (Default: 1)\n");
	printf("\t-s, --save-imgs        Save images\n");
endfunction

% Quantization matrix
Q1 = [16,  11,  10,  16,  24,  40,  51,  61;
      12,  12,  14,  19,  26,  58,  60,  55;
      14,  13,  16,  24,  40,  57,  69,  56;
      14,  17,  22,  29,  51,  87,  80,  62;
      18,  22,  37,  56,  68, 109, 103,  77;
      24,  35,  55,  64,  81, 104, 113,  92;
      49,  64,  78,  87, 103, 121, 120, 101;
      72,  92,  95,  98, 112, 100, 103,  99];

% The following options can be altered using command-line arguments
save_imgs = 0;    % Save images option. Default value: False
use_absolute = 0; % Use absolute value option to calculate entropy of F-caret.
                  % Default value: False - The minimum negative value is added
		  % to each element in order to eliminate negative values.
q_multiplier = 1; % Quantization matrix scalar multiplier. Default value: 1
                  % Q = q_multiplier * Q1

% Parse command-line arguments.
read_multiplier = 0;
arg_list = argv();
for i = 1:nargin()
	if (read_multiplier)
		read_multiplier = 0;
		m = str2num(arg_list{i});
		if (m > 0)
			q_multiplier = floor(m);
		else
			printf("[WARNING]: Invalid multiplier value! Ignoring...\n\n");
		endif
		continue;
	endif
	if (strncmp(arg_list{i}, "--save-imgs", length("--save-imgs")) ||
			strncmp(arg_list{i}, "-s", length("-s")))
		save_imgs = 1;
	elseif (strncmp(arg_list{i}, "--use-absolute", length("--use-absolute")) ||
			strncmp(arg_list{i}, "-a", length("-a")))
		use_absolute = 1;
	elseif (strncmp(arg_list{i}, "--multiplier", length("--multiplier")) ||
			strncmp(arg_list{i}, "-m", length("-m")))
		read_multiplier = 1;
	elseif (strncmp(arg_list{i}, "--help", length("--help")) ||
			strncmp(arg_list{i}, "-h", length("-h")))
		print_usage();
		return;
	else
		print_usage();
		return;
	endif
endfor

printf("Quantization matrix multiplier = %d\n", q_multiplier);

f = imread('cameraman.tif');  % Read image as a matrix
H = entropy(f);               % Calculate entropy of image f
printf("Entropy of original image f (in bits/symbol) = %f\n", H);

rows = rows(f);
cols = columns(f);
% If image f cannot be divided in 8x8 blocks, exit.
if (mod(rows,8) != 0 || mod(cols,8) != 0)
	printf("Image size is not multiple of 8!\n");
	printf("Cannot partition image to 8x8 blocks.\n");
	return;
endif

% From this point on, blocks are of size 8x8

rowb = fix(rows/8);      % Rows can be partitioned in rowb blocks
colb = fix(cols/8);      % Columns can be partitioned in colb blocks
block_num = rowb * colb; % Total number of blocks

% Partition image f in blocks
row_block_sizes = ones(1,rowb) * 8;
col_block_sizes = ones(1,colb) * 8;
f_blocks = mat2cell(f, row_block_sizes, col_block_sizes);

% Calculate quantization matrix
Q = Q1 * q_multiplier;

% For every block:
for k = 1:rowb
	for l = 1:colb
		b = f_blocks{k,l};   % Let b hold current block
		F_blocks{k,l}       = dct2(b);   % Conduct a 2D DCT in current block
		F_caret_blocks{k,l} = round(F_blocks{k,l}./Q);    % Quantize DCT coefficients
		F_tilde_blocks{k,l} = F_caret_blocks{k,l}.*Q;     % "Reverse quantization"
		I_blocks{k,l}       = idct2(F_tilde_blocks{k,l}); % Inverse 2D DCT
	endfor
endfor

% Reconstruct images F-caret and I by concatenating the 8x8 blocks
for k = 1:rowb
	F_caret_rows{k} = cat(2, F_caret_blocks{k,:});
	I_rows{k} = cat(2, I_blocks{k,:});
endfor
F_caret = cat(1, F_caret_rows{:});
I = cat(1, I_rows{:});

% Calculate entropy of F_caret
if (use_absolute)
	% Use absolute value to avoid negative values in F_caret
	H = entropy(abs(F_caret));
	printf("Entropy of |F-caret| (in bits/symbol) = %f\n", H);
else
	% Find the minimum negative value of F_caret and if it exists,
	% add its opposite to each element of F_caret. This will eliminate
	% all negative values. F_caret matrix is modified as it isn't used
	% after this point.
	minval = min(F_caret(:));
	if (minval < 0)
		F_caret += -1 * minval;
	endif
	H = entropy(F_caret);
	printf("Entropy of F-caret (in bits/symbol) = %f\n", H);
endif

i = uint8(I);  % Convert image I to unsigned 8-bit integer type

% The following two lines seem redundant but it's better to be safe than sorry
i(i < 0) = [0];      % Make sure no negative values exist in image i
i(i > 255) = [255];  % Make sure no values greater that 255 exist in image i

peaksnr = psnr(i, f);   % Calculate Peak Signal-to-noise Ratio of image i
printf("PSNR = %.4f dB\n", peaksnr);

H = entropy(i);   % Calculate entropy of recreated image i
printf("Entropy of recreated image i (in bits/symbol) = %f\n", H);

#{
colormap(gray); imagesc(i)
pause(3);
#}

% Save image i in PNG format (lossless) if required
if (save_imgs)
	filename = sprintf("part2_%d.png", q_multiplier);
	printf("\nSaving %s...\n\n", filename);
	imwrite(i, filename);
endif

