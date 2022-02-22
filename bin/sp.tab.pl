#!/usr/bin/perl
use strict;
use Getopt::Long;
use Data::Dumper;
use utf8;
use Encode;

=head1  Usage
usage: perl $0 [<options>]
options:
	-db db
	-reads species tab
	-depth species tab
	-help   print help information
USAGE

=cut

my($db,$reads,$depth,$help);
GetOptions(
	"db:s" => \$db,
	"reads:s" => \$reads,
	"depth:s" =>\$depth,
	"help!" => \$help,

);

die `pod2text $0` unless (defined $db && defined $reads && defined $depth);
die `pod2text $0` if defined $help;

my %tab_db;
my %xls_db;
my %hash_seq;
open IN,$db || die $!;
my $ti=<IN>;
chomp $ti;
my @ti=split/\t/,$ti;
shift @ti;
while (<IN>) {
	chomp;
	my @l=split/\t/;
	my @or=split/\,/,$l[1];
	for my $s (@or){
		$hash_seq{$l[0]}{$s}=1;
	}
	
	$tab_db{$l[0]}=join("\t",$l[2],$l[3],$l[4],$l[5]);
	$l[3]=encode("GBK",decode("utf-8",$l[3]));
	$l[4]=encode("GBK",decode("utf-8",$l[4]));
	$l[5]=encode("GBK",decode("utf-8",$l[5]));
	$xls_db{$l[0]}=join("\t",$l[2],$l[3],$l[4],$l[5]);
}

close IN;

my (%sp,%seq);
my %tab_reads;
open IN,$reads||die $!;
while (<IN>) {
	chomp;
	my @l=split/,/;
	my @or = split /\_/,$l[0];
	my $seq = pop @or;

	my $sp = join(" ",@or);
	$tab_reads{$sp}{$seq}=$l[1];
	$sp{$sp}=1;
#	$seq{$seq}=1;
}
close IN;
my @file=split/\./,$reads;
my $xls_name=$file[0].".report.xls";
open OUT ,">$xls_name"||die$!;
print join("\t","L_name","Target_seq_reads","Total","Type","C_name_g","C_name_s", "Encyclo"),"\n";
print OUT  join("\t","L_name","Target_seq_reads","Total","Type","C_name_g","C_name_s", "Encyclo"),"\n";
my @o_sp=sort keys %sp;
#my @o_seq=sort keys %seq;
for my $m (@o_sp){
	print $m;
	print OUT $m;
	my @out;
	my $tmp_total=0;
	for my $k (sort keys %{$hash_seq{$m}}){
		if ($tab_reads{$m}{$k}) {
			push @out,$k.":".$tab_reads{$m}{$k};
			$tmp_total += $tab_reads{$m}{$k};
		}else{
			push @out,$k.":0";
		}
	}
	print "\t",join(";",@out),"\t",$tmp_total;
	print OUT "\t",join(";",@out),"\t",$tmp_total;
	print "\t",$tab_db{$m},"\n";
	print OUT "\t",$xls_db{$m},"\n";
}
close OUT;

############# version before 20210727############
#my %tab_depth;
#open IN,$depth||die $!;

#<IN>;
#while (<IN>) {
#	chomp;
#	my @l=split/,/;
#	my @or = split /\_/,$l[0];
#	my $seq = pop @or;
#	my $sp = join(" ",@or);
#	$tab_depth{$sp}{$seq}=$l[2]/$l[1];
#	$sp{$sp}=1;
#	$seq{$seq}=1;
#}
#close IN;








############# version before 20210727############
#print Dumper(\%hash_seq);
#my @o_sp=sort keys %sp;
#my @o_seq=sort keys %seq;
#print "L_name";
#print OUT "L_name";
#for my $s (@o_seq){
#	print "\t","Reads_",$s,"\t","Depth_",$s;
#	print OUT "\t","Reads_",$s,"\t","Depth_",$s;
#}
#print "\t",join("\t",@ti),"\n";
#print OUT "\t",join("\t",@ti),"\n";










#for my $m (@o_sp){
#	print $m;
#	print OUT $m;
#	for my $n (@o_seq){
#		if (exists $hash_seq{$m}{$n} ) {
#			if (exists $tab_reads{$m}{$n}) {
#				print "\t",$tab_reads{$m}{$n};
#				printf "\t%0.2f", $tab_depth{$m}{$n};
#				print OUT "\t",$tab_reads{$m}{$n};
#				printf OUT "\t%0.2f", $tab_depth{$m}{$n};
#			}else{
#				print "\t0\t0";
#				print OUT "\t0\t0";
#			}
			

#		}else{
			
#				print "\t-\t-";
#				print OUT "\t-\t-";
			
			
#		}
#	}
#	if (exists $tab_db{$m}) {
#		print "\t",$tab_db{$m},"\n";
#		print OUT "\t",$xls_db{$m},"\n";
#	}else{
#		print "\t-\n";
#		print OUT "\t-\n";
#	}
#}
#close OUT;
