#!/usr/bin/env octave

% Developed using GNU Octave, version 4.2.2
% Used packages: 1) image  v2.6.2

% Load required packages
pkg load image    % Contains function: psnr, entropy


% Function definition
function print_usage()
	printf("USAGE: ./%s [OPTIONS]\n", program_name());
	printf("Available options:\n");
	printf("\t-h, --help             Display this information\n");
	printf("\t-s, --save-imgs        Save images\n");
endfunction

function retval = SAD(a,b)
	retval = sum(sum(abs(a - b)));
endfunction

% The following options can be altered using command-line arguments
save_imgs = 0;    % Save images option. Default value: False

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


frame178 = imread('frame178.tif');  % Read frame178 as a matrix
frame179 = imread('frame179.tif');  % Read frame179 as a matrix

rows178 = rows(frame178);
cols178 = columns(frame178);

% If image frame178 cannot be divided in 4x4 blocks, exit.
if (mod(rows178,4) != 0 || mod(cols178,4) != 0)
	printf("Image size is not multiple of 4!\n");
	printf("Cannot partition frame178 to 4x4 blocks.\n");
	return;
endif

rowb = fix(rows178/4);      % Rows can be partitioned in rowb 4x4 blocks
colb = fix(cols178/4);      % Columns can be partitioned in colb 4x4 blocks
block_num = rowb * colb; % Total number of 4x4 blocks

% Partition frame178 in 4x4 blocks
row_block_sizes = ones(1,rowb) * 4;
col_block_sizes = ones(1,colb) * 4;
frame178_blocks = mat2cell(frame178, row_block_sizes, col_block_sizes);

QP = 25;

% For every 4x4 block:
for k = 1:rowb
	for l = 1:colb
		b = frame178_blocks{k,l};   % Let b hold current 4x4 block
		b = double(b); % Cast uint8 to double to avoid integer_transform complaining
		F_blocks{k,l}       = integer_transform(b);   % Conduct 2D DCT integer approximation
		F_caret_blocks{k,l} = quantization(F_blocks{k,l}, QP);    % Quantize 'DCT' coefficients
		F_tilde_blocks{k,l} = inv_quantization(F_caret_blocks{k,l}, QP);  % "Reverse quantization"
		I_blocks{k,l}       = inv_integer_transform(F_tilde_blocks{k,l}); % Inverse 2D 'DCT'
	endfor
endfor

% Reconstruct images F-caret and I by concatenating the 4x4 blocks
for k = 1:rowb
	F_caret_rows{k} = cat(2, F_caret_blocks{k,:});
	I_rows{k} = cat(2, I_blocks{k,:});
endfor
F_caret = cat(1, F_caret_rows{:});
I = cat(1, I_rows{:});

i = round(I/64); % Perform the post-scaling required by the H.264
i = uint8(i);    % Convert image I to unsigned 8-bit integer type

% The following two lines seem redundant but it's better to be safe than sorry
i(i < 0) = [0];      % Make sure no negative values exist in image i
i(i > 255) = [255];  % Make sure no values greater that 255 exist in image i

% Calculate entropy of F_caret
H = entropy(uint8(abs(F_caret)));
printf("Entropy of |F-caret| (in bits/symbol) = %f\n", H);

peaksnr = psnr(i, frame178);   % Calculate Peak Signal-to-noise Ratio of image i
printf("PSNR of the recreated image i = %.4f dB\n", peaksnr);

#{
colormap(gray); imagesc(i)
pause(3);
#}

% Save image i in PNG format (lossless) if required
if (save_imgs)
	filename = sprintf("regenerated_f178.png");
	printf("\nSaving %s...\n\n", filename);
	imwrite(i, filename);
endif

rows179 = rows(frame179);
cols179 = columns(frame179);

% If image frame179 cannot be divided in 16x16 blocks, exit.
if (mod(rows179,16) != 0 || mod(cols179,16) != 0)
	printf("Image size is not multiple of 16!\n");
	printf("Cannot partition frame178 to 16x16 blocks.\n");
	return;
endif

rowb = fix(rows179/16);      % Rows can be partitioned in rowb 16x16 blocks
colb = fix(cols179/16);      % Columns can be partitioned in colb 16x16 blocks
block_num = rowb * colb; % Total number of 16x16 blocks

% Partition frame179 in 16x16 blocks
row_block_sizes = ones(1,rowb) * 16;
col_block_sizes = ones(1,colb) * 16;
frame179_blocks = mat2cell(frame179, row_block_sizes, col_block_sizes);

r = i;

% For every 16x16 block:
skips = 0;
for k = 1:rowb
	for l = 1:colb
		b = frame179_blocks{k,l};   % Let b hold current 16x16 block
		b = double(b); % Cast uint8 to double to avoid integer_transform complaining
		xmin = 1 + (k-1)*16;
		ymin = 1 + (l-1)*16;
		xmax = k * 16;
		ymax = l * 16;

		a = r(xmin:xmax, ymin:ymax);
		sad = SAD(a,b);
		if (sad < 150)
			skips++;
			MVs{k,l} = [0,0];
			continue;
		endif

		minSAD = {-1, [-10,-10]};
		for i = -6:6
			for j = -6:6
				if (xmin+i < 1 || ymin+j < 1 ||
						xmax+i > rows179 || ymax+j > cols179)
					continue;
				endif
				a = r((xmin+i):(xmax+i), (ymin+j):(ymax+j));
				sad = SAD(a,b);
				if (minSAD{1} == -1 || sad < minSAD{1})
					minSAD{1} = sad;
					minSAD{2} = [i,j];
				endif
			endfor
		endfor
		MVs{k,l} = minSAD{2};
	endfor
endfor

MVs

printf('Blocks skipped: %2d\n', skips);

