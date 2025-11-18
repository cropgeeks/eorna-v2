#!/bin/bash

#SBATCH --cpus-per-task=8
#SBATCH -o slurm-%x_%A_%a.out 
#SBATCH --mem=9g
#SBATCH --partition=long
#SBATCH --array=1-20



##################################################################
#parameters
##################################################################
#FASTA file with query sequences

workingDir=`pwd`

queryDir=$workingDir/input
query="EORNA2_RTD.longestProteins.part_"$SLURM_ARRAY_TASK_ID".fa"

#BLAST database with subject sequences
#this script assumes the required index files have already been built with makeblastdb
dbdir=blast/dbs/
db=uniprot_trembl_plants.fasta

#tab-delimited output with additional fields (.txt extension)
outputFile=EORNA2_RTD_vs_trembl.$SLURM_ARRAY_TASK_ID.txt

#e-value cut-off
evalue=1e-20

#cutoff for % query coverage
qcov_hsp_perc=80


##################################################################
#get processing
##################################################################

echo "copy the input data to the local temp dir on node $HOSTNAME"
date
cd $TMPDIR
cp -v $queryDir/$query .
echo "copy the database to the local temp dir"
date
cp -v $dbdir/$db.* .
echo "done copying required data:"
ls -lh
date

source activate blast

echo "outputFile = $outputFile"

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
-num_threads $SLURM_CPUS_PER_TASK

echo "add a header to the output table"
cat BLAST_tableHeader.txt $prefix.raw > $prefix.withHeader

#extract top blast hit for each query
awk '! a[$1]++' $prefix.withHeader > $outputFile

echo "BLAST run complete"

echo "copy output files back to main storage"
cp -v $outputFile $workingDir
cp -v $prefix.withHeader $workingDir

echo "workflow complete"
date



