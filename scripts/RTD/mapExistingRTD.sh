
# Genome fasta file: $genome_fasta
# Transcriptome fasta file: $trans_fasta
# Output sam file: $output_sam
# Max intron size: $intron_max
# prefix: prefix of the output file name


intron_max=15000
minimap2 \
-t 16 \
-G $intron_max \
-L \
--secondary=no \
--MD \
-ax splice:hq -uf $genome_fasta $trans_fasta > $output_sam

####

prefix=${output_sam%.*}
samtools view -Sb -F 2048 ${prefix}.sam > ${prefix}.bam
samtools sort ${prefix}.bam > ${prefix}_sorted.bam

bedtools bamtobed -bed12 -i ${prefix}_sorted.bam > ${prefix}.bed
bedToGenePred ${prefix}.bed ${prefix}.genepred
genePredToGtf "file" ${prefix}.genepred ${prefix}.gtf
