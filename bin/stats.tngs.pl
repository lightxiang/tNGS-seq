#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use utf8;
use Encode;
use Cwd qw(abs_path);
my %hash;
my %sum;
my %species;
@ARGV==2||die$!;

my (%sample,%check);

my %cname;
my $file=`ls $ARGV[0]/*.report.tmp`;
my @line=split/\n/,$file;
for my $l (@line) {
	my @file=split/\//,$l;
	my @name=split/\-/,$file[-1];
	$sample{$name[0]}=1;
	open IN,$l||die$!;
	my $title=<IN>;
	chomp $title;
	my @title=split/\t/,$title;
	
#	my @id;
#	for my $i (0..$#title){
#		if (exists $title{$title[$i]}) {
#			push @id,$i;
#		}
#	}
	while (<IN>) {
		chomp;
		my @or=split/\t/;

		if($or[5] eq "-"){
			$cname{$or[0]}=$or[0];
		}else{
			$cname{$or[0]}=$or[5];
		}
		$sum{$name[0]}+=$or[2];
		my @seq=split/\;/,$or[1];
		for my $s (@seq){
			my @tmp_seq=split/\:/,$s;
			$hash{$name[0]}{$or[0]}{$tmp_seq[0]}=$tmp_seq[1];
			$species{$or[0]}{$tmp_seq[0]}=1;
		}



	}
	close IN;
}
my %qc;
open IN,$ARGV[1]||die$!;
<IN>;
while (<IN>) {
	chomp;
	my @or=split/\,\"/;
	my @l=split/,/,$or[0];
	my @m=split/,/,$or[1];
	#s/,\".+\",//;
	#s/,\".+\",//;

	#print $_,"\n";
	#my @l=split/,/;
	my @name=split/\-/,$l[0];
	$qc{$name[0]}=join(",",$l[-1],$m[-1]);
}
close IN;



my @sam = sort keys %sample;
#print Dumper(\%title);
my @sp = sort keys %species;
open OUT, ">merge.summary.csv";
print "Sample,Raw_reads,Clean_reads,Total_species_reads";
print OUT "Sample,Raw_reads,Clean_reads,Total_species_reads";
for my $sp (@sp){
	my $tmp_name=$cname{$sp};
	$tmp_name=encode("GBK",decode("utf-8",$tmp_name));
	print OUT ",",$tmp_name;
	for my $sq (sort keys %{$species{$sp}}){
		if (exists $species{$sp}{$sq}) {
			#print ",",$sp,":",$sq;
			
			print ",",$tmp_name,":",$sq;
		}
		
	}
}
print "\n";
print OUT "\n";

print "Sample,Raw_reads,Clean_reads,Total_species_reads";
print OUT "Sample,Raw_reads,Clean_reads,Total_species_reads";
for my $sp (@sp){
	#my $tmp_name=$cname{$sp};
	#$tmp_name=encode("GBK",decode("utf-8",$tmp_name));
	print OUT ",",$sp;
	for my $sq (sort keys %{$species{$sp}}){
		if (exists $species{$sp}{$sq}) {
			print ",",$sp,":",$sq;
			
			#print ",",$tmp_name,":",$sq;
		}
		
	}
}
print "\n";
print OUT "\n";


for my $sa (sort keys %hash){
	print join(",",$sa,$qc{$sa},$sum{$sa}) ;
	print OUT join(",",$sa,$qc{$sa},$sum{$sa}) ;
	for my $sp (@sp){
		my $sum=0;
		for my $sq (sort keys %{$species{$sp}}){
			if (exists $species{$sp}{$sq}){
					if(exists $hash{$sa}{$sp}{$sq}) {
						print ",",$hash{$sa}{$sp}{$sq};
						$sum += $hash{$sa}{$sp}{$sq};
					}else{
						print ",0";
					}
				
			}else{
				#print ",-";
			}
		}
		print OUT ",",$sum;
	}
	print "\n";
	print OUT "\n";
}
close OUT;

