#!/usr/bin/env octave

% Developed using GNU Octave, version 4.2.2
% Used packages: 1) image  v2.6.2

% Load required packages
pkg load image    % Contains function: psnr, entropy


% Function definitions
function print_usage()
	printf("USAGE: ./%s [OPTIONS]\n", program_name());
	printf("Available options:\n");
	printf("\t-h, --help             Display this information\n");
	printf("\t-Q, --qp  QP           Quantization Parameter (Default: 25)\n");
	printf("\t-s, --save-imgs        Save images\n");
endfunction


% Sum of Absolute Differences
function retval = SAD(a,b)
	retval = sum(sum(abs(a - b)));
endfunction


% Partition image in (bs)x(bs) blocks
% Parameters: 1) Input Image
%             2) Block Size
% Return Values: 1) Blocks
%                2,3) Row and column count of (bs)x(bs) blocks
function [blocks, rowb, colb] = partition_image(image, bs)
	rows = rows(image);
	cols = columns(image);

	% If image cannot be divided in (bs)x(bs) blocks, exit.
	if (mod(rows,bs) != 0 || mod(cols,bs) != 0)
		printf("Image size is not multiple of %2d!\n", bs);
		printf("Cannot partition image to %2dx%2d blocks.\n", bs, bs);
		return;
	endif

	rowb = fix(rows/bs);   % Rows can be partitioned in rowb (bs)x(bs) blocks
	colb = fix(cols/bs);   % Columns can be partitioned in colb (bs)x(bs) blocks
	block_num = rowb * colb;  % Total number of (bs)x(bs) blocks

	% Partition image in (bs)x(bs) blocks
	row_block_sizes = ones(1,rowb) * bs;
	col_block_sizes = ones(1,colb) * bs;
	blocks = mat2cell(image, row_block_sizes, col_block_sizes);
endfunction


% Divide image in 4x4 blocks, conduct 2D 'DCT' integer approximation,
% quantize 'DCT' coefficients, calculate entropy of the quantized coefficients,
% "Reverse Quantization", inverse 2D 'DCT' and perform H.264 post-scaling.
% Parameters: 1) Input Image
%             2) Quantization Parameter
% Return Values: 1)   Inverse transform result
%                2,3) Image row and column count
%                4)   Entropy of quantized coefficients
function [i, rows, cols, H] = TQIH(image, QP)
	% Partition image in 4x4 blocks
	[blocks, rowb, colb] = partition_image(image, 4);
	rows = rowb * 4;
	cols = colb * 4;

	% For every 4x4 block:
	for k = 1:rowb
		for l = 1:colb
			% Let b hold current 4x4 block
			b = blocks{k,l};
			% Cast uint8 to double to avoid integer_transform() complaining
			b = double(b);
			% Conduct 2D DCT integer approximation
			F_blocks{k,l} = integer_transform(b);
			% Quantize 'DCT' coefficients
			F_caret_blocks{k,l} = quantization(F_blocks{k,l}, QP);
			% "Reverse quantization"
			F_tilde_blocks{k,l} = inv_quantization(F_caret_blocks{k,l}, QP);
			% Inverse 2D 'DCT'
			I_blocks{k,l} = inv_integer_transform(F_tilde_blocks{k,l});
		endfor
	endfor

	% Reconstruct images F-caret and I by concatenating the 4x4 blocks
	F_caret = cell2mat(F_caret_blocks);
	I = cell2mat(I_blocks);

	i = round(I/64); % Perform the post-scaling required by the H.264
	i = uint8(i);    % Convert image I to unsigned 8-bit integer type

	% The following two lines seem redundant but it's better to be safe than sorry
	i(i < 0) = [0];      % Make sure no negative values exist in image i
	i(i > 255) = [255];  % Make sure no values greater that 255 exist in image i

	% Calculate entropy of F_caret
	H = entropy(uint8(abs(F_caret)));
endfunction


% The following options can be altered using command-line arguments
save_imgs = 0;    % Save images option. Default value: False
QP = 25;          % Quantization Parameter. Default value: 25

% Parse command-line arguments.
read_qp = 0;
arg_list = argv();
for i = 1:nargin()
	if (read_qp)
		read_qp = 0;
		qp = str2num(arg_list{i});
		if (qp > 0)
			QP = floor(qp);
		else
			printf("[WARNING]: Invalid QP value! Ignoring...\n\n");
		endif
		continue;
	endif
	if (strncmp(arg_list{i}, "--save-imgs", length("--save-imgs")) ||
			strncmp(arg_list{i}, "-s", length("-s")))
		save_imgs = 1;
	elseif (strncmp(arg_list{i}, "--qp", length("--qp")) ||
                        strncmp(arg_list{i}, "-Q", length("-Q")))
		read_qp = 1;
	elseif (strncmp(arg_list{i}, "--help", length("--help")) ||
			strncmp(arg_list{i}, "-h", length("-h")))
		print_usage();
		return;
	else
		print_usage();
		return;
	endif
endfor

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Step #1                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

frame178 = imread('frame178.tif');  % Read frame178 as a matrix
frame179 = imread('frame179.tif');  % Read frame179 as a matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Step #2                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

printf("\n################### QP = %2d ###################\n", QP);

[r178, rows178, cols178, H178] = TQIH(frame178, QP);

printf("Entropy of the quantized coefficients of frame 178 (in bits/symbol) = %f\n", H178);

peaksnr = psnr(r178, frame178);   % Calculate PSNR of the recreated frame 178
printf("PSNR of the recreated frame 178 = %.4f dB\n", peaksnr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Step #3                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Partition image in 16x16 blocks
[frame179_blocks, rowb, colb] = partition_image(frame179, 16);

rows179 = rowb * 16;
cols179 = colb * 16;;

skips = 0;               % Counter for the number of skip blocks
skip = false(rowb,colb); % Boolean array holding whether a block is skip
% For every 16x16 block:
for k = 1:rowb
	for l = 1:colb
		b = frame179_blocks{k,l};  % Let b hold current 16x16 block
		b = double(b);
		xmin = 1 + (k-1)*16;
		ymin = 1 + (l-1)*16;
		xmax = k * 16;
		ymax = l * 16;

		% Check if current block is a skip
		a = r178(xmin:xmax, ymin:ymax);
		a = double(a); % Required for calculating SAD because
		               % uint8 cannot store negative values (a-b).
		sad = SAD(a,b);
		if (sad < 150)
			skips++;
			MVs{k,l} = [0,0];
			skip(k,l) = 1;
			continue; % Skip the 13^2-1 checks of full search
		endif

		minSAD = {-1, [-10,-10]}; % {min SAD value, MV that resulted in the min SAD}
		% Perform full search
		for i = -6:6
			for j = -6:6
				% Ignore blocks that lie outside of frame 178 boundaries
				if (xmin+i < 1 || ymin+j < 1 ||
						xmax+i > rows178 || ymax+j > cols178)
					continue;
				endif
				a = r178((xmin+i):(xmax+i), (ymin+j):(ymax+j));
				a = double(a); % Required for calculating SAD
				sad = SAD(a,b);
				% Update min SAD if needed
				if (minSAD{1} == -1 || sad < minSAD{1})
					minSAD{1} = sad;
					minSAD{2} = [i,j];
				endif
			endfor
		endfor
		MVs{k,l} = minSAD{2};  % Calculated motion vector of current block
		% printf("[%2d,%2d] %6d (%2d,%2d)\n", k, l, minSAD{1}, minSAD{2});
	endfor
endfor

% Used for debug purposes
% MVs
% skip

printf('Blocks skipped: %2d\n', skips);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Steps #4,5                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For every 16x16 block:
for k = 1:rowb
	for l = 1:colb
		xmin = 1 + (k-1)*16;
		ymin = 1 + (l-1)*16;
		xmax = k * 16;
		ymax = l * 16;

		% (i,j): MV
		i = MVs{k,l}(1);
		j = MVs{k,l}(2);

		% (ni,nj): MV with noise in [-2,2]
		if (skip(k,l) == 1) % Do not add noise in MVs of skip blocks
			ni = nj = 0;
		else
			do
				ni = i + (unidrnd(5)-3);
			until (xmin+ni >= 1 && xmax+ni <= rows178)
			do
				nj = j + (unidrnd(5)-3);
			until (ymin+nj >= 1 && ymax+nj <= cols178)
		endif

		% Compensate motion for block (k,l) using the corresponding
		% motion vector and the recreated frame 178.
		p  = r178((xmin+i):(xmax+i), (ymin+j):(ymax+j));
		np = r178((xmin+ni):(xmax+ni), (ymin+nj):(ymax+nj));
		Prediction_blocks{k,l} = p;
		Noise_Prediction_blocks{k,l} = np;
		% Calculate prediction error
		if (skip(k,l) == 1) % In case of skip blocks, set prediction error to zero
			PredErr_blocks{k,l} = zeros(16, 16);
			Noise_PredErr_blocks{k,l} = zeros(16, 16);
		else
			PredErr_blocks{k,l} = frame179(xmin:xmax, ymin:ymax) - p;
			Noise_PredErr_blocks{k,l} = frame179(xmin:xmax, ymin:ymax) - np;
		endif
	endfor
endfor

% Reconstruct images Pred and PredErr by concatenating the 16x16 blocks
Pred = cell2mat(Prediction_blocks); % Prediction
PredErr = cell2mat(PredErr_blocks); % Prediction Error
Noise_Pred = cell2mat(Noise_Prediction_blocks); % Prediction [Noise MVs]
Noise_PredErr = cell2mat(Noise_PredErr_blocks); % Prediction Error [Noise MVs]

[rPE, rowsPE, colsPE, HPE] = TQIH(PredErr, QP);
[nrPE, nrowsPE, ncolsPE, nHPE] = TQIH(Noise_PredErr, QP);

printf("Entropy of the quantized coefficients of Prediction Error (in bits/symbol) = %f\n", HPE);
printf("Entropy of the quantized coef. of Pred. Error [NOISE MVs] (in bits/symbol) = %f\n", nHPE);

r179 = Pred + rPE; % Recreate frame 179 using prediction and recreated prediction error
nr179 = Noise_Pred + nrPE; % Recreate frame 179 [Noise MVs]

peaksnr = psnr(r179, frame179);         % Calculate PSNR of frame 179
noise_peaksnr = psnr(nr179, frame179);  % Calculate PSNR of frame 179 [Noise MVs]
printf("PSNR of the recreated frame 179 = %.4f dB\n", peaksnr);
printf("PSNR of the recreated frame 179 [NOISE MVs] = %.4f dB\n", noise_peaksnr);

#{
colormap(gray); imagesc(r178)
pause(3);
colormap(gray); imagesc(Pred)
pause(3);
colormap(gray); imagesc(r179)
pause(3);
colormap(gray); imagesc(frame179)
pause(3);
colormap(gray); imagesc(PredErr)
pause(3);
#}

if (save_imgs)
	filename = sprintf("recreated_f178_qp%2d.png", QP);
	printf("\nSaving %s...\n", filename);
	imwrite(r178, filename);
	filename = sprintf("recreated_f179_gp%2d.png", QP);
	printf("Saving %s...\n", filename);
	imwrite(r179, filename);
	filename = sprintf("prediction_f179_qp%2d.png", QP);
	printf("Saving %s...\n", filename);
	imwrite(Pred, filename);
	filename = sprintf("prediction_error_f179_qp%2d.png", QP);
	printf("Saving %s...\n", filename);
	imwrite(PredErr, filename);
	filename = sprintf("recreated_f179_gp%2d_noise.png", QP);
	printf("Saving %s...\n", filename);
	imwrite(nr179, filename);
	filename = sprintf("prediction_f179_qp%2d_noise.png", QP);
	printf("Saving %s...\n", filename);
	imwrite(Noise_Pred, filename);
	filename = sprintf("prediction_error_f179_qp%2d_noise.png", QP);
	printf("Saving %s...\n", filename);
	imwrite(Noise_PredErr, filename);
endif

