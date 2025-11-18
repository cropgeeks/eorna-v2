#!/bin/bash

#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=100m
#SBATCH --partition=short

combinedFile=EORNA2_RTD_vs_trembl.all.txt

files=`ls -1 *.withHeader`
for file in ${files[*]}
do	
	echo "appending file $file"
	tail -n +2 $file >> EORNA2_RTD_vs_trembl.all.txt
done

