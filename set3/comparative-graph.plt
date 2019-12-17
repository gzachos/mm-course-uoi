#!/usr/bin/env gnuplot --persist

# Developed by George Z. Zachos

set terminal pngcairo enhanced font "arial,11" fontscale 1.0
set output './plots/comparative-graph.png'
set bar 1.000000 front
set xlabel "Bitrate (kbps)"
set ylabel "Y-PSNR (dB)"
set grid
set colorbox vertical origin screen 0.9, 0.2, 0 size screen 0.05, 0.6, 0 front bdefault
set style line 1 lc rgb '#ccab41' pt 11 lw 2 ps 1.5
set style line 2 lc rgb '#407cc7' pt 13 lw 2 ps 1.5
set style line 3 lc rgb '#ed4d4a' pt 9 lw 2 ps 1.5
set style line 4 lc rgb '#3ab542' pt 3 lw 2 ps 1.5
set key on inside bottom box
INFILE='./plot-data/bitrate_y-psnr.dat'
plot INFILE using 1:2 title 'H.264 IPP' with linespoints ls 1, \
     INFILE using 3:4 title 'H.264 IBP' with linespoints ls 2, \
     INFILE using 5:6 title 'H.265 Low-delay' with linespoints ls 3, \
     INFILE using 7:8 title 'H.265 Random-access' with linespoints ls 4

