#!/bin/bash
#
# generate probed velocities for points in probesDict with field magU.

echo -e "\n"
echo "sample for velocity probes evaluation"

#probeLocations

#get the name of the first directory in postProcessing/probes
timeDir=$(ls postProcessing/probes/ | head -n 1)

## Erstellen eines Diagramms mit GnuPlot

echo "ploting diagram"
gnuplot <<- EOF

    set terminal pngcairo size 1600,600 enhanced font 'Verdana,10'
    set title 'Velocity probe on selected points'
	set xlabel 'time [s]'
    set ylabel 'velocity [m/s]'
    set grid
	outfile = 'postProcessing/velocityProbes/velocity_diagram.png'
	set output outfile

	set key outside

	firstTimeDir = system('echo $timeDir')

    #get the first line, merge spaces into one space, put each space in a line, count the lines
    numOfPoints = system('head -n1 postProcessing/probes/'.firstTimeDir.'/magU | tr -s " " | grep -o " " | wc -l')
    numOfPoints = numOfPoints-1

    ###MITTELWERT
	# get the mean for each point and print it to a file StatDat.dat
	set print "StatDat.dat"
	do for [i=2:numOfPoints+1] {
	  stats  'postProcessing/probes/'.firstTimeDir.'/magU' u i nooutput ;
	  print STATS_mean
	}
	set print

	# transpose StatDat.dat file and append it to the probed files (slow, but for the moment the only solution :( )
	system('> meanValues; while IFS= read line; do cut -f1 StatDat.dat | paste -s >> meanValues; done < postProcessing/probes/'.firstTimeDir.'/magU')
	system('paste postProcessing/probes/'.firstTimeDir.'/magU meanValues > dataToPlot')

    #get the coordinates from each point and append it to meanValues
    system('sed "s/ \+ /\t/g" postProcessing/probes/'.firstTimeDir.'/magU > magUtabs')
    system('sed "/^#/!d" magUtabs > points')
    system('> trData')
    do for [i=3:numOfPoints+2] {
        system('cut -f'.i.' points | paste -s >> trData')
    }
    system('paste trData StatDat.dat > postProcessing/velocityProbes/meanValues.txt')
    print 'Mean values in: postProcessing/velocityProbes/meanValues.txt'

    set cbrange [0:100]
	plot for [i=2:numOfPoints+1] 'dataToPlot' using 1:i with linespoints palette cb (i-2)*(100/numOfPoints) title 'point '.(i-1),\
		for [i=numOfPoints+2:(numOfPoints*2)+1] 'dataToPlot' using 1:i with lines palette cb (i-numOfPoints-2)*(100/numOfPoints) title 'mean velocity point '.(i-numOfPoints-1)

	print 'Plot image generated in: '.outfile

EOF
rm StatDat.dat meanValues dataToPlot magUtabs trData points
