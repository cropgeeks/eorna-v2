#!/bin/bash

#SBATCH --cpus-per-task=16
#SBATCH -o slurm-%x_%A.out 
#SBATCH --mem=1g
#SBATCH --partition=short


##################################################################
#command line parameters
##################################################################
#FASTA file with query sequences
query=EORNA2_RTD.longestProteins.fa

#BLAST database with subject sequences
#this script assumes the required index files have already been built with makeblastdb
db=blast/dbs/uniprot_sprot_plants.fasta

#tab-delimited output with additional fields (.txt extension)
outputFile=EORNA2_RTD_vs_sprot.txt

#e-value cut-off
evalue=1e-20

#cutoff for % query coverage
qcov_hsp_perc=80

#number of threads for parallel processing
#gets set automatically, to the value provided for SGE in the SGE options in the script header (-pe flag)
num_threads=$SLURM_CPUS_PER_TASK


##################################################################
#get processing
##################################################################

source activate blast

echo "make a header file for the output table"
echo -e "qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbitscore\tqlen\tslen\tqcovs\tqcovhsp\tsalltitles" > BLAST_tableHeader.txt 

#extract a prefix for temp file naming from the output file name
prefix=`basename $outputFile .txt`
echo "prefix for output file = $prefix"

echo "run the BLAST job"
blastp \
-query $query \
-db $db \
-outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore qlen slen qcovs qcovhsp salltitles" \
-out $prefix.raw \
-qcov_hsp_perc $qcov_hsp_perc \
-evalue $evalue \
-num_threads $num_threads

echo "add a header to the output table"
cat BLAST_tableHeader.txt $prefix.raw > $prefix.withHeader

#extract top blast hit for each query
awk '! a[$1]++' $prefix.withHeader > $outputFile

rm BLAST_tableHeader.txt
rm $prefix.raw
# rm $prefix.withHeader

echo "BLAST run complete"

