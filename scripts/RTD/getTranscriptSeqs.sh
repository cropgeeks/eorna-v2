genome=PSVCP_20Pangenome_21.05.fasta
gtf=EoRNA2_rtd.gtf
fasta=EoRNA2_rtd.fasta

gffread -w $fasta -g $genome $gtf
