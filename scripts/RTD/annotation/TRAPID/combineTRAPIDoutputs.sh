#!/bin/bash

#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=2g
#SBATCH --partition=medium

rootDir=EORNA2_RTD
faiFile=/$rootDir/annotation/trapid/input/EORNA2_RTD.longest.fa.fai #use only the longest transcripts, one per gene
outputDir=$rootDir/annotation/trapid/output

java \
-Xmx2g \
utils.oneoffs.CombineTRAPIDData \
$faiFile \
$outputDir/transcripts_go_exp7407.txt \
$outputDir/transcripts_interpro_exp7407.txt \
$outputDir/structural_data_exp7407.txt \
EORNA2_RTD_combinedAnnotation_TRAPID_10Oct2024.txt


