#!/usr/bin/perl


# Converts a fasta file into sql for adding to the transcript_sequences tables in eorna2

use strict;

print "use eorna2;\n";


$/ = "\n>";

open (FASTA, "BaRT2v18.fa");

while(<FASTA>){

    $_ =~ s/\n>//;

    my($transcript_id, $sequence) = split(/\n/, $_, 2);

    $transcript_id =~ s/>//;

    $sequence =~ s/\s+//g;

    my $seq_length = length($sequence); 

    my($gene_id, $transcript_number) = split(/\./, $transcript_id, 2);

    my($chr, $id) = split(/G/, $gene_id, 2);

    $chr =~ s/BaRT2v18//;

    print "insert into transcript_sequences(transcript_id, dataset_name, gene_id, chr_id, transcript_sequence, seq_length) values 
    (\"$transcript_id\", \"BaRT2v18\", \"$gene_id\", \"$chr\", \"$sequence\", \"$seq_length\");\n";

}