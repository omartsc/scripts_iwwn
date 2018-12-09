#!/bin/bash

echo -e "\n"
echo "sample for velocity probes evaluation"

#if [ ! -d ./postProcessing ]; then
#	mkdir postprocessing
#fi
#
if [ ! -d ./postProcessing/velocityProbes ]; then
	mkdir postProcessing/velocityProbes
else
	rm postProcessing/velocityProbes/*
fi
#
#if [ -d ./postProcessing/sets ]; then
#	read -p "-> The sets directory exists already. Do you want to sample again (y/n)? " ans1
#	if [ "$ans1" == "y" ]; then
#		echo "sampling and writing to file: sample_output"
#		echo "..."
#		sample > postProcessing/sample_output
#	fi
#else
#	echo "sampling and writing to file: sample_output"
#	echo "..."
#	sample > postProcessing/sample_output
#fi

# Zeitdatei erstellen
grep -F 'Time = ' postProcessing/sample_output | grep -o '[^=^ ]\+$' > time_temp

# in which column is the probed velocity?
numColVel=5
# create empty file velocity_temp
> velocity_temp
for probesFile in ./postProcessing/sets/*/probes_alpha.water_magU.xy; do
	# transpose the column velocity and append to file velocity_temp
	cut -f $numColVel $probesFile | paste -s >> velocity_temp

	# get the points, used for labes in plot
	# (to improve: get points from sampleDict)
	# (or make that cut works for one arbitrary directory in postProcessing/sets/)
	cut -f -3 --output-delimiter=',' $probesFile > points_temp
done

###mehrere Punkte in eine Tab mit mehreren spalten
# generate table to plot with time in the first column and velocity of all points
paste time_temp velocity_temp > postProcessing/velocityProbes/table_velocity


###Mittelwert pro spalte


# Zeit mit WSP verknüpfen
#paste postProcessing/velocityProbes/time_temp postProcessing/velocityProbes/velocity_temp | awk '{print $1, $2}' >> postProcessing/velocityProbes/table_velocity
#rm postProcessing/velocityProbes/velocity_temp
#rm postProcessing/velocityProbes/time_temp

## Erstellen eines Diagramms mit GnuPlot

# format the points as string x,y,z (delete spaces for gnuplot to read each point as string)
cat points_temp | tr -d [:blank:] > points_coord
echo "ploting diagram"
gnuplot <<- EOF
    set terminal pngcairo size 1600,600 enhanced font 'Verdana,10'
    set title 'Velocity probe on selected points'
	set xlabel 'time [s]'
    set ylabel 'velocity [m/s]'
    set grid
	set output 'postProcessing/velocityProbes/velocity_diagram.png'
	points = system('cat points_coord')
	item(n) = word(points,n)
	set key outside
	plot for [col=2:words(points)+1] 'postProcessing/velocityProbes/table_velocity' using 1:col with linespoints title item(col-1)
EOF
rm points_coord points_temp velocity_temp time_temp
