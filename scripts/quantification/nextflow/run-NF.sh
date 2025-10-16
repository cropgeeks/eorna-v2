#!/bin/bash

#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=1G
#SBATCH --partition=long

nextflow run EORNA.nf -with-trace -with-report report.html