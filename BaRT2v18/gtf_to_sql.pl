#!/usr/bin/perl

use strict;

print "use eorna2;\n";

my $exon_number;
my $prev_transcript_id;

open (GTF, "BaRT2v18.gtf");

while(<GTF>){

    $_ =~ s/\s+$//;

    my($chr, $source, $feature, $start, $end, $score, $strand, $frame, $attribute) = split(/\t/, $_, 9);

    if ($feature eq "exon"){

    
    my ($transcript_id, $gene_id) = split(/\"\; /, $attribute, 2);
    
    $gene_id =~ s/gene_id \"//;
    $gene_id =~ s/\"\;//;
    $transcript_id =~ s/transcript_id \"//;

    
    if($transcript_id ne $prev_transcript_id){
      $exon_number = 0;
    }

    $exon_number++;

    print "insert into transcript_structure(transcript_id, dataset_name, f_start, f_end, gene_id, chr_id, strand, exon_number) values 
    (\"$transcript_id\", \"BaRT2v18\", \"$start\", \"$end\", \"$gene_id\", \"$chr\", \"$strand\", \"$exon_number\");\n";

    $prev_transcript_id = $transcript_id;

  }




}