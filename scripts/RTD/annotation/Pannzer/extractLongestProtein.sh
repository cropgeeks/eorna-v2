#!/bin/bash


#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=1g
#SBATCH --partition=short

echo "extract longest proteins"

java \
utils.transcriptomics.FindLongestTranscript \
EoRNA2_rtd_transfeat_coding_pep.fa.fai \
> longestProteins.txt

cut -f 2 longestProteins.txt > protIDs.txt

echo "subset FASTA file"
seqkit grep \
--pattern-file protIDs.txt \
EoRNA2_rtd_transfeat_coding_pep.fa \
> EORNA2_RTD.longestProteins.fa

echo "done"