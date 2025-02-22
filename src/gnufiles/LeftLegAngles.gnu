set title "Articular values for a straight forward walking: 6 steps of 0.2 m on the right foot"
set xlabel "Time (iteration numbers x 0.005)"
set ylabel "Radians"
plot "DDO.dat" u 1 w l t "R_HIP_Z", "DDO.dat" u 2 w l t "R_HIP_X", "DDO.dat" u 3 w l t "R_HIP_Y", "DDO.dat" u 4 w l t "R_KNEE", "DDO.dat" u 5 w l t "R_ANKLE_Y", "DDO.dat" u 6 w l t "R_ANKLE_X"
