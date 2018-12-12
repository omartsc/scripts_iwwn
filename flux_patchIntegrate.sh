#!/bin/bash
# Description:	Runs the patchIntegrate postprocessing tool of OpenFOAM and creates a table with two
#				columns - one column is the time and the other is the correspondent integrated value.
#				After creating the table a diagram is plotted via gnuPlot.
# Use:	optinally make script executable:	$ chmod +x flux_patchIntegrate.sh
# 		run script:	$ . flux_patchIntegrate.sh
#		enter name of patch where the flux is required

echo -e "\n"

#if [ ! -d ./postProcessing ]; then
#	mkdir postprocessing
#fi
#
#if [ ! -d ./postProcessing/fluxVsTime ]; then
#	mkdir postProcessing/fluxVsTime
#fi
#
echo "patchIntegrate for phiWater evaluation"
read -p "-> enter name of patch: " patchName
#echo "integrating and writing to file: phiWater_${patchName}"
#echo "..."
#patchIntegrate alphaPhi10 "$patchName" > postProcessing/fluxVsTime/phiWater_"$patchName"

echo "processing integrated data"
grep -F 'Time = ' postProcessing/fluxVsTime/phiWater_"${patchName}" | grep -o '[^=^ ]\+$' > postProcessing/fluxVsTime/time
grep -F 'Integral of alphaPhi10' postProcessing/fluxVsTime/phiWater_"$patchName" | grep -o '[^=^ ^-]\+$' > postProcessing/fluxVsTime/flux
echo "writing data to file -> table_phiWater_${patchName}"
paste postProcessing/fluxVsTime/time postProcessing/fluxVsTime/flux > postProcessing/fluxVsTime/table_phiWater_"$patchName"
rm postProcessing/fluxVsTime/time postProcessing/fluxVsTime/flux

echo "ploting diagram"
# list all patches that already have a flux vs time file
ls postProcessing/fluxVsTime | grep -F "table_phiWater_" | sed 's/table_phiWater_//g' > existingPatches
gnuplot <<- EOF
    set terminal pngcairo size 800,600 enhanced font 'Verdana,10'
    set title 'flux of phase fraction 1 (phi water) over time at patch'
    set xlabel 'time [s]'
    set ylabel 'flux of water phase [m³/s]'
    set grid
    outfile = 'postProcessing/fluxVsTime/fluxVsTime_diagram.png'
    set output outfile
    patches = system('cat existingPatches')
    plot for [patch in patches] 'postProcessing/fluxVsTime/table_phiWater_'.patch with linespoints title patch
    print 'Plot image generated in: '.outfile
EOF
rm existingPatches
echo "done"
