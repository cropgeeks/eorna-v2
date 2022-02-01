#!/usr/bin/perl

# Converts a fasta file into sql for adding to the gene_annotation table in eorna2

use strict;

print "use eorna2;\n";

$/ = "\n>";

my %seq_details;
my $prev_transcript_number = 1;

open (FASTA, "BaRT2v18.fa");

while(<FASTA>){

    $_ =~ s/\n>//;

    my($transcript_id, $sequence) = split(/\n/, $_, 2);

    $transcript_id =~ s/>//;

    my($gene_id, $transcript_number) = split(/\./, $transcript_id, 2);

    # if($transcript_number > $prev_transcript_number){
    #     $seq_details{$gene_id} = $transcript_number;
    # }

    $seq_details{$gene_id}++;

    $prev_transcript_number = $transcript_number;
}

$/ = "\n";

open (ANNOT, "BaRT_2_18_annotation_genes.txt");

while(<ANNOT>){

    if($_ =~ /^BaRTv2 gene/){
        next;
    }

    $_ =~ s/\s+$//;

    my($gene_id, $chr_id, $gene_start, $gene_end, $strand, $sources, $end_support, $pannzer_annotation, $go_ids, $go_terms, $coding_potentiality) = split(/\t/, $_, 11);

    $pannzer_annotation =~ s/\'/\\\'/g;
    $go_terms =~ s/\'/\\\'/g;

    print "insert into gene_annotation(gene_id, dataset_name, chr_id, number_of_transcripts, gene_start, gene_end, strand, pannzer_annotation, go_ids, go_terms) values (\"$gene_id\", \"BaRT2v18\", \"$chr_id\", \"$seq_details{$gene_id}\", \"$gene_start\", \"$gene_end\", \"$strand\", \"$pannzer_annotation\", \"$go_ids\", \"$go_terms\");\n";


}