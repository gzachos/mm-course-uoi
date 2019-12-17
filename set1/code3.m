#!/usr/bin/env octave

% +-----------------------------------------------------------------------+
% |                Copyright (C) 2020 George Z. Zachos                    |
% +-----------------------------------------------------------------------+
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% You should have received a copy of the GNU General Public License along
% with this program; if not, write to the Free Software Foundation, Inc.,
% 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
%
% Contact Information:
% Name: George Z. Zachos
% Email: gzzachos <at> gmail.com

% Developed using GNU Octave, version 4.2.2

% Create sample AC coefficient array
AC_coef = [7, 0, 3, 0, 2, 3, 0, 0, 2, 4, 0, 1, 0, 0, 0, 1, 0, 0, -1, -1, 0, 1, 0, 0, 0, 1];
z = zeros(1, 63 - columns(AC_coef));
AC_coef = cat(2, AC_coef, z);

% This function performs Run-Length Encoding in the 63 quantized
% AC coefficients of an 8x8 block
function RLE(AC)
	% Check the size of the array given as parameter
	if (rows(AC) != 1 || columns(AC) != 63)
		printf("Parameter should be a matrix of size 1x63\n");
		return;
	endif

	printf("(LEVEL,RUN)\n");
	run = 0;
	for i = 1:columns(AC)
		if (AC(i) == 0)
			run++;
		else
			printf("(%2d,%2d)\n", AC(i), run);
			run = 0; % Reset current number of zeros
		endif
	endfor
endfunction

% Call RLE function passing sample array as parameter
RLE(AC_coef);

