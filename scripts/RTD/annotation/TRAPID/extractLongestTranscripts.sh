#!/bin/bash


#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=2g
#SBATCH --partition=short

echo "extract longest transcripts"

java \
utils.transcriptomics.FindLongestTranscript \
../../../EoRNA2_rtd.fasta.fai \
> longestTranscripts.txt

cut -f 2 longestTranscripts.txt > transcriptIDs.txt

echo "subset FASTA file"
seqkit grep \
--pattern-file transcriptIDs.txt \
../../../EoRNA2_rtd.fasta \
> EORNA2_RTD.longest.fa

echo "split subset FASTA file"
seqkit split \
--by-part 2 \
EORNA2_RTD.longest.fa

mkdir EORNA2_RTD.longest.fa.split

echo "compress subset file 1"
pigz \
--best \
-c \
EORNA2_RTD.longest.fa.split/EORNA2_RTD.longest.part_001.fa \
> EORNA2_RTD.longest.fa.1.gz

echo "compress subset file 2"
pigz \
--best \
-c \
EORNA2_RTD.longest.fa.split/EORNA2_RTD.longest.part_002.fa \
> EORNA2_RTD.longest.fa.2.gz

echo "done"