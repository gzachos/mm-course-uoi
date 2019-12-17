#!/usr/bin/env octave

H264_R_B0 = [97.600, 146.27, 195.01, 243.93];
H264_P_B0 = [35.374, 37.475, 38.974, 40.179];

H264_R_B1 = [97.450, 146.38, 194.96, 244.06];
H264_P_B1 = [35.959, 38.016, 39.291, 40.569];

H265_R_LD = [97.4864, 145.3256, 194.9936, 243.2448];
H265_P_LD = [37.5133, 39.68280, 41.26000, 42.46210];

H265_R_RA = [98.6568, 147.4544, 196.3240, 245.0168];
H265_P_RA = [37.7569, 39.87090, 41.47020, 42.69930];

printf('# H.264 IPP vs H.264 IBP\n');
BD_PSNR = bjontegaard2(H264_R_B0, H264_P_B0, H264_R_B1, H264_P_B1, 'dsnr')
BD_Rate = bjontegaard2(H264_R_B0, H264_P_B0, H264_R_B1, H264_P_B1, 'rate')

printf('\n# H.264 IPP vs H.265 Low-delay\n');
BD_PSNR = bjontegaard2(H264_R_B0, H264_P_B0, H265_R_LD, H265_P_LD, 'dsnr')
BD_Rate = bjontegaard2(H264_R_B0, H264_P_B0, H265_R_LD, H265_P_LD, 'rate')

printf('\n# H.264 IPP vs H.264 Random-access\n');
BD_PSNR = bjontegaard2(H264_R_B0, H264_P_B0, H265_R_RA, H265_P_RA, 'dsnr')
BD_Rate = bjontegaard2(H264_R_B0, H264_P_B0, H265_R_RA, H265_P_RA, 'rate')

