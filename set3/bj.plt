#!/usr/bin/env gnuplot --persist

set terminal pngcairo enhanced font "arial,11" fontscale 1.0
set output 'metric-comparative.png'
set bar 1.000000 front
set xlabel "BD-PSNR"
set ylabel "BD-Rate"
set grid
set colorbox vertical origin screen 0.9, 0.2, 0 size screen 0.05, 0.6, 0 front bdefault
set style line 1 lc rgb '#ccab41' pt 3 lw 2 ps 2
set style line 2 lc rgb '#407cc7' pt 7 lw 2 ps 2
set style line 3 lc rgb '#ed4d4a' pt 13 lw 2 ps 2
set key on inside top box
INFILE='bj.dat'
plot INFILE using 1:2 title 'H.264 IPP vs H.264 IBP' with points ls 1, \
     INFILE using 3:4 title 'H.264 IPP vs H.265 Low-delay' with points ls 2, \
     INFILE using 5:6 title 'H.264 IPP vs H.265 Random-access' with points ls 3

