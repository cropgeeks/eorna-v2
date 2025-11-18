#!/bin/bash

#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=20g
#SBATCH --partition=short

pathToJar=ahrd.jar

echo "run AHRD"
date

java \
-Xmx19g \
-jar $pathToJar \
ahrd_input.yml

echo "AHRD run complete"
date
