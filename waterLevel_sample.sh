#!/bin/bash
# Description:	Runs the sample postprocessing tool of OpenFOAM and creates a table with two
#				columns - one column is the time and the other is the correspondent water level
#				at a defined line.
#				After creating the table a diagram is plotted via gnuPlot.
# Use:	optinally make script executable:	$ chmod +x waterLevel_sample.sh
# 		run script:	$ . waterLevel_sample.sh
#		optionally choose whether the sample command shell be executed again or not

echo -e "\n"
echo "sample for water level evaluation"

#if [ ! -d ./postProcessing ]; then
#	mkdir postprocessing
#fi
#
if [ ! -d ./postProcessing/waterLevelVsTime ]; then
	mkdir postProcessing/waterLevelVsTime
else
	rm postProcessing/waterLevelVsTime/*
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
#	echo "sampling and writing to file -> sample_output"
#	echo "..."
#	sample > postProcessing/sample_output
#fi

# Ausdünnung der aufgenommen Werte
echo "remove all lines with *e-* and 0"
for i in ./postProcessing/sets/*/*.xy; do
	sed -i '/e-/d' $i
	sed -i '/\s0$/d' $i
done

# Ausdünnung aufgenommen Werte
echo "keep only data for values closest to 0.5"
for i in ./postProcessing/sets/*/*.xy; do
	awk '{if (NR>1 && $2 < 0.5 && prev2 > 0.5) {print prev1, prev2; print $1, $2} prev1=$1; prev2=$2}' $i > $i.out1
done

# nur maximal z Werte behalten
echo "keep only data for maximum Z values"
for i in ./postProcessing/sets/*/*.out1; do
	tail -n 2 $i > $i.out2
done

# Interpolation des z-Wertes der WSP-Lage auf exakt 0.5 (alpha.water)
echo "interpolate z-value for alpha.water 0.5"
for i in ./postProcessing/sets/*/*.out2; do
	awk '{if (NR>1) {x=0.5; x2=$2; y2=$1; y=(y2-y1)/(x2-x1)*(x-x1)+y1; print y, x} x1=$2; y1=$1}' $i > $i.out3
done

# Zeitdatei erstellen
grep -F 'Time = ' postProcessing/sample_output > postProcessing/waterLevelVsTime/fltimes
grep -o '[^=^ ]\+$' postProcessing/waterLevelVsTime/fltimes > postProcessing/waterLevelVsTime/time_temp

# Wert aus dritter Spalte für jeden Zeitschritt nehmen und in einer Datei auflisten
for e in ./postProcessing/sets/*/*.out3; do
	cut -d" " -f1 $e >> postProcessing/waterLevelVsTime/waterLevel_temp
done

###Mittelwert pro spalte


# Zeit mit WSP verknüpfen
paste postProcessing/waterLevelVsTime/time_temp postProcessing/waterLevelVsTime/waterLevel_temp | awk '{print $1, $2}' >> postProcessing/waterLevelVsTime/table_waterLevel
rm postProcessing/waterLevelVsTime/waterLevel_temp
rm postProcessing/waterLevelVsTime/time_temp
rm postProcessing/waterLevelVsTime/fltimes

# Erstellen eines Diagramms mit GnuPlot
echo "ploting diagram"
gnuplot <<- EOF
    set terminal pngcairo size 1600,600 enhanced font 'Verdana,10'
    set title 'water level over time at sample line'
	set xlabel 'time [s]'
    set ylabel 'height [m]'
    set grid
	set output 'postProcessing/waterLevelVsTime/waterLevel_diagram.png'
	stats 'postProcessing/waterLevelVsTime/table_waterLevel' u 2 nooutput ;
	set print 'postProcessing/waterLevelVsTime/meanValueWaterLevel.txt'
	print STATS_mean
	set print
	plot 'postProcessing/waterLevelVsTime/table_waterLevel' with linespoints title "water level", STATS_mean title sprintf("mean value = %1.4f",STATS_mean)
EOF
