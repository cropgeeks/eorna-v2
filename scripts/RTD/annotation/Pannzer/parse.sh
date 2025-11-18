#!/bin/bash

#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=1g
#SBATCH --partition=long


java utils.go.ParsePannzerOutput_anno \
anno.out \
EORNA2_RTD \
"EoRNA2_chr\dH\d{6}" \
"EoRNA2_chr\dH\d{6}.\d+"