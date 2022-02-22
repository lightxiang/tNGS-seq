#!/usr/bin/perl -w
use strict;
use Data::Dumper;
@ARGV==1||die$!;
my %hash;
my %stats;


open IN,$ARGV[0]||die$!;

while (<IN>) {
	chomp;
	my @l=split/\t/;
	$stats{$l[2]}++;
}

close IN;

for my $k (sort keys %stats){
	print $k,",",$stats{$k},"\n";
}
