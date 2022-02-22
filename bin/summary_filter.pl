#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use utf8;

use Encode;
use JSON;
use Cwd qw(abs_path);
my %hash;
my %sum;
my %species;
@ARGV==3||die$!;

my (%sample,%negctrl,%json_to_report);## %negctrl 存放阴性样本数据

my %cname;
###### 读取各样本结果
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
			#$tmp_name=encode("GBK",decode("utf-8",$or[5]));
			#$cname{$or[0]}=encode("GBK",decode("utf-8",$or[5]));
			$cname{$or[0]}=$or[5];
		}
		$sum{$name[0]}+=$or[2];
		my @seq=split/\;/,$or[1];
		$json_to_report{$name[0]}{$or[0]}{"Seq_details"}=join("/",@seq);
		for my $s (@seq){
			my @tmp_seq=split/\:/,$s;

			if ($name[0] =~ /tPLNTC/) {
				$negctrl{$name[0]}{$or[0]}{$tmp_seq[0]}=$tmp_seq[1];
				#$json_to_report{$name[0]}{$or[0]}{$tmp_seq[0]}=$tmp_seq[1];
			}else{
				$hash{$name[0]}{$or[0]}{$tmp_seq[0]}=$tmp_seq[1];
				#$json_to_report{$name[0]}{$or[0]}{$tmp_seq[0]}=$tmp_seq[1];
				$species{$or[0]}{$tmp_seq[0]}=1;
			}
			
		}


 
	}
	close IN;
}




my (%qc,%clean);
open IN,$ARGV[1]||die$!;
<IN>;
while (<IN>) {
	chomp;
	s/(\".+\")(.+)(\".+\")/$2/;
	#print $_,"\n";
	#if(s/(\".+\")(.+)(\".+\")/$2/){
	#	print $1,"\n";
	#	print $2,"\n";
	#	print $3,"\n";
	#};
	#print $_,"\n";
	my @l=split/\,/;
	my @name=split/\-/,$l[0];
	$clean{$name[0]}=$l[7];
	$json_to_report{$name[0]}{"Summary"}{"before-total_reads"}=$l[2];
	$json_to_report{$name[0]}{"Summary"}{"after-total_reads"}=$l[7];
	#$qc{$name[0]}=join(",",$l[-1],$m[-1]);
}
close IN;



my %coef;
open IN,$ARGV[2]||die$!;
my $base=<IN>;
chomp $base;
my @base=split/\t/,$base;
my $cp_base=$base[1];
while (<IN>) {
	chomp;
	my @l=split/\t/;
	$coef{$l[0]}=$l[1];
}
close IN;


#print Dumper(\%hash);

my %fi_ctrl;
### 过滤阴性样本检出靶标
%fi_ctrl = &getfilter_ctrl(\%negctrl,\%hash);

#print Dumper(\%fi_ctrl);

open ALL,">all.sample.report.csv";
print ALL join(",","Sample","Copy_Num","Total","Normal_Total","Max","Normal_Max","Target_num","Filter_NTC_Copy_Num","Filter_NTC_Total","Filter_NTC_Normal_Total","Filter_NTC_Max","Filter_NTC_Normal_Max","Filter_NTC_Target_num","Confidence","L_name","C_name"),"\n";

my (%summary_total,%summary_max,%summary_sp,@cp_stats);
for my $name (keys %hash){
	my $file_name=$name.".report.txt";
	open OUT,">$file_name";
	print OUT join("\t","L_name","C_name","Copy_Num","Total","Normal_Total","Max","Normal_Max","Target_num","Seq_details","NTC_detected","Filter_NTC_Copy_Num","Filter_NTC_Total","Filter_NTC_Normal_Total","Filter_NTC_Max","Filter_NTC_Normal_Max","Filter_NTC_Target_num","Fitlter_NTC_Seq_details","Confidence"),"\n";
	for my $sp (sort keys %{$hash{$name}}){
		my (@ori,@aft,$ntc_detected,@aft_print);
		$ntc_detected="N";
		for my $seq (keys %{$hash{$name}{$sp}}){
			push @ori,$hash{$name}{$sp}{$seq};
			if (!$fi_ctrl{$sp}{$seq}) {
				push @aft,$hash{$name}{$sp}{$seq};
				push @aft_print,$seq.":".$hash{$name}{$sp}{$seq};
			}else{
				$ntc_detected="Y";
				push @aft,0;
				push @aft_print,$seq.":0";
			}
		}
		$json_to_report{$name}{$sp}{"NTC_detected"}=$ntc_detected;
		my ($ori_total,$ori_max,$ori_target)=&get_total_max(@ori);
		my ($aft_total,$aft_max,$aft_target)=&get_total_max(@aft);
		my $aft_details=join("/",sort(@aft_print));
		push @{$summary_total{$name}{$sp}},$ori_total;
		push @{$summary_total{$name}{$sp}},$aft_total;
		#push @{$summary_total{$name}{$sp}},$ori_target;
		push @{$summary_max{$name}{$sp}},$ori_max;
		push @{$summary_max{$name}{$sp}},$aft_max;
		$summary_sp{$sp}=1;

		############ copy number
		my $cp_coef;
		if ($coef{$sp}) {
			$cp_coef=$coef{$sp};
		}else{
			$cp_coef=$coef{"Others"};
		}
		#print $cp_coef,"\n";
		my $external=$hash{$name}{"external"}{"seq1"};
		my $ori_cp = &get_target_cp($cp_base,$cp_coef,$external,$ori_total);
		my $aft_cp = &get_target_cp($cp_base,$cp_coef,$external,$aft_total);
		$ori_cp = sprintf("%d",$ori_cp);
		$aft_cp = sprintf("%d",$aft_cp);
		if ($ori_total != 0) {
			$ori_cp++;
		}
		if ($aft_total != 0) {
			$aft_cp++;
		}

		push @cp_stats,$name.",".$sp.",".$aft_cp;

		########### normalization 
		my $normal_ori = &get_normal($ori_total,$clean{$name});
		my $normal_aft = &get_normal($aft_total,$clean{$name});
		$normal_ori = sprintf("%d",$normal_ori);
		$normal_aft = sprintf("%d",$normal_aft);
		$normal_ori++;
		$normal_aft++;
		my $normal_ori_max = &get_normal($ori_max,$clean{$name});
		my $normal_aft_max = &get_normal($aft_max,$clean{$name});
		$normal_ori_max = sprintf("%d",$normal_ori_max);
		$normal_aft_max = sprintf("%d",$normal_aft_max);
		$normal_ori_max++;
		$normal_aft_max++;
		if ($aft_total==0) {
			$normal_aft=0;
			$normal_aft_max=0;
		}
		######### score 
		my $score = &get_score($aft_cp,$normal_aft_max,$aft_target);
		#####
		#my $utf8_name=decode("GBK",$cname{$sp});
		my $utf8_name=$cname{$sp};
		print OUT join("\t",$sp,$utf8_name,$ori_cp,$ori_total,$normal_ori,$ori_max,$normal_ori_max,$ori_target,$json_to_report{$name}{$sp}{"Seq_details"},$ntc_detected,$aft_cp,$aft_total,$normal_aft,$aft_max,$normal_aft_max,$aft_target,$aft_details,$score),"\n";
		print ALL join(",",$name,$ori_cp,$ori_total,$normal_ori,$ori_max,$normal_ori_max,$ori_target,$aft_cp,$aft_total,$normal_aft,$aft_max,$normal_aft_max,$aft_target,$score,$sp,$cname{$sp}),"\n";
		#### json ###
		#$score,$sp,$cname{$sp})		
#		"Confidence","L_name","C_name"),"\n";
		$json_to_report{$name}{$sp}{"Copy_Num"}=$ori_cp;
		$json_to_report{$name}{$sp}{"Total"}=$ori_total;
		$json_to_report{$name}{"Summary"}{"on-target_reads"}+=$ori_total;
		$json_to_report{$name}{$sp}{"Normal_Total"}=$normal_ori;
		$json_to_report{$name}{$sp}{"Max"}=$ori_max;
		$json_to_report{$name}{$sp}{"Normal_Max"}=$normal_ori_max;
		$json_to_report{$name}{$sp}{"Target_num"}=$ori_target;
		$json_to_report{$name}{$sp}{"Filter_NTC_Copy_Num"}=$aft_cp;
		$json_to_report{$name}{$sp}{"Filter_NTC_Total"}=$aft_total;
		$json_to_report{$name}{$sp}{"Filter_NTC_Normal_Total"}=$normal_aft;
		$json_to_report{$name}{$sp}{"Filter_NTC_Max"}=$aft_max;
		$json_to_report{$name}{$sp}{"Filter_NTC_Normal_Max"}=$normal_aft_max;
		$json_to_report{$name}{$sp}{"Filter_NTC_Target_num"}=$aft_target;
		$json_to_report{$name}{$sp}{"Confidence"}=$score;
		$json_to_report{$name}{$sp}{"C_name"}=decode("utf8",$cname{$sp});
		#$json_to_report{$name}{$sp}{"C_name"}=$cname{$sp};





		############################
	}
	close OUT;

}
close ALL;
for my $n (keys %negctrl){
	my $file_name=$n.".report.txt";
	open OUT,">$file_name";
	print OUT join("\t","L_name","C_name","Total","Max","Target_num","Seq_details"),"\n";
	for my $s (sort keys %{$negctrl{$n}}){
		my @out;
		for my $q (keys %{$negctrl{$n}{$s}}){
			push @out,$negctrl{$n}{$s}{$q};
		}
		my ($ntc_total,$ntc_max,$ntc_target)=&get_total_max(@out);
		push @{$summary_total{$n}{$s}},$ntc_total;
		push @{$summary_total{$n}{$s}},$ntc_total;
		push @{$summary_max{$n}{$s}},$ntc_max;
		push @{$summary_max{$n}{$s}},$ntc_max;
		$summary_sp{$s}=1;
		#my $utf8_name=decode("GBK",$cname{$s});
		my $utf8_name=$cname{$s};
		print OUT join("\t",$s,$utf8_name,$ntc_total,$ntc_max,$ntc_target,$json_to_report{$n}{$s}{"Seq_details"}),"\n";
		$json_to_report{$n}{$s}{"Total"}=$ntc_total;
		$json_to_report{$n}{"Summary"}{"on-target_reads"}+=$ntc_total;
		$json_to_report{$n}{$s}{"Max"}=$ntc_max;
		$json_to_report{$n}{$s}{"Target_num"}=$ntc_target;
		$json_to_report{$n}{$s}{"C_name"}=decode("utf8",$cname{$s});
		#$json_to_report{$n}{$s}{"C_name"}=$cname{$s};
		#$json_to_report{$n}{$s}{"Total"}=$ntc_total;

	}
	close OUT;
}

###########################################################################
my @order_sample=sort keys %summary_sp;
open OUT, ">total.summary.csv";

print OUT "Sample";
for my $s (@order_sample){
	print OUT ",",$cname{$s},":Total,",$cname{$s},":Filter_NTC_Total";
}
print OUT "\n";

print OUT "Sample";
for my $s (@order_sample){
	print OUT ",",$s,":Total,",$s,":Filter_NTC_Total";
}
print OUT "\n";
for my $sam (sort keys %summary_total){
	print OUT $sam;
	for my $sp (@order_sample){
		if (exists $summary_total{$sam}{$sp}) {
			print OUT ",",join(",",@{$summary_total{$sam}{$sp}});
		}else{
			print OUT ",0,0";
		}

	}
	print OUT "\n";

}
close OUT;
##########################################################################################
open OUT, ">max.summary.csv";

print OUT "Sample";
for my $s (@order_sample){
	print OUT ",",$cname{$s},":Max,",$cname{$s},":Filter_NTC_Max";
}
print OUT "\n";

print OUT "Sample";
for my $s (@order_sample){
	print OUT ",",$s,":Max,",$s,":Filter_NTC_Max";
}
print OUT "\n";
for my $sam (sort keys %summary_total){
	print OUT $sam;
	for my $sp (@order_sample){
		if (exists $summary_total{$sam}{$sp}) {
			print OUT ",",join(",",@{$summary_total{$sam}{$sp}});
		}else{
			print OUT ",0,0";
		}

	}
	print OUT "\n";

}
close OUT;

################################

open OUT, ">cp_num.stats.csv";
print OUT join("\n",@cp_stats),"\n";
close OUT;


my $json = encode_json \%json_to_report;
$json =~ s/\:\{/\:\n    \{/g;
$json =~ s/},/},\n    /g;
$json =~ s/}},\n    /}},\n/g;
print "$json\n";



######## sub functions ##################################
### %fi_ctrl = &getfilter_ctrl(\%negctrl,\%hash);
### 第一版 过滤条件：靶标在阴性样本出现*40 %以上的样本中出现，为问题靶标，需要剔除；
### 第二版 过滤条件：靶标在阴性样本出现，且reads数>=5，为问题靶标，需要剔除。
sub getfilter_ctrl {
	
	my (%tmp_hash,%table_hash,$tmp_hash,$table_hash);
	($tmp_hash,$table_hash) = @_;
	%tmp_hash = %{$tmp_hash};
	%table_hash = %{$table_hash};
	#print Dumper(\%tmp_hash);
	##################################################################################
	##                               第一版  start                                  ##
	##################################################################################
	#my @num=keys %tmp_hash;
	#my $num=@num;
	##$num=$num/2;
	#my %num;
	#for my $k (keys %tmp_hash){
	#	for my $s (keys %{$tmp_hash{$k}}){
	#		for my $q (keys %{$tmp_hash{$k}{$s}}){
	#			if ($tmp_hash{$k}{$s}{$q}) {
	#				$num{$s}{$q} += $tmp_hash{$k}{$s}{$q};
	#			}
	#		}
	#	}
	#}
	#my %ctrl;
	#for my $s (keys %num){
	#	for my $q (keys  %{$num{$s}}){
	#		#if ($num{$s}{$q} >= $num) {
	#		if ($num{$s}{$q} >= 1) {
	#			$ctrl{$s}{$q}=1;
	#		}
	#	}
	#}
	#
	#my %out;

	#my @num_table=keys %table_hash;
	#my $num_table=@num_table;
	#$num_table = 1;
	##$num_table = 0.4 * $num_table;

	#for my $n (keys %table_hash){
	#	for my $s (keys %{$table_hash{$n}}){
	#		for my $q (keys %{$table_hash{$n}{$s}}){
	#			if ($ctrl{$s}{$q} && $table_hash{$n}{$s}{$q}) {
	#				#print join("\t",$n,$s,$q),"\n";
	#				$out{$s}{$q}++;
	#			}
	#		}
	#	}
	#}	

	#my %return;
	#for my $s (keys %out){
	#	for my $q (keys %{$out{$s}}){
	#		if ($out{$s}{$q} >= $num_table) {
	#			$return{$s}{$q}=1;
	#		}
	#	}
	#}

	##print Dumper (\%return);
	#return %return;

	##################################################################################
	##                               第一版  end                                    ##
	##################################################################################


	##################################################################################
	##                               第二版  start                                  ##
	##################################################################################
	my %num;
	for my $k (keys %tmp_hash){
		for my $s (keys %{$tmp_hash{$k}}){
			for my $q (keys %{$tmp_hash{$k}{$s}}){
				if ($tmp_hash{$k}{$s}{$q}) {
					$num{$s}{$q} += $tmp_hash{$k}{$s}{$q};
				}
			}
		}
	}

	my %ctrl;
	for my $s (keys %num){
		for my $q (keys  %{$num{$s}}){
			#if ($num{$s}{$q} >= $num) {
			if ($num{$s}{$q} >= 5) {
				$ctrl{$s}{$q}=1;
			}
		}
	}

	return %ctrl;
	##################################################################################
	##                               第一版  end                                    ##
	##################################################################################



}

#######

sub get_total_max {
	my (@arr)=@_;
	@arr=sort{$b<=>$a} @arr;
	my $total=0;
	my $n_target=0;
	for my $i (@arr){
		$total += $i;
		if ($i != 0) {
			$n_target++;
		}
	}
	return $total,$arr[0],$n_target;
	#print Dumper(\@arr);
}

sub get_target_cp {
	#$cp_base,$cp_coef,$external,$ori_total
	#my $cp_base=shift;
	#my $cp_coef=shift;
	my ($cp_base,$cp_coef,$external,$ori_total)=@_;
	my $cp=$cp_base * $cp_coef * $ori_total / $external;
	return $cp;
}

sub get_normal {

	my ($ori,$clean)=@_;
	my $nor=100000 * $ori / $clean;
	return $nor;
}

sub get_score{
	my ($cp,$max,$seq) = @_;
	my $flag=0;
	if ($cp >=1 && $cp < 500) {
		$flag += 1;
	}elsif($cp >= 500 && $cp < 2000){
		$flag += 2;
	}elsif($cp >= 2000 ){
		$flag += 3;
	}

	if ($max >=1 && $max < 5) {
		$flag += 1;
	}elsif($max >=1 && $max < 20){
		$flag += 2;
	}elsif($max >= 20) {
		$flag += 3;
	}

	if ($seq == 1) {
		$flag += 1;
	}elsif($seq == 2){
		$flag += 2;
	}elsif($seq >= 3){
		$flag += 3;
	}

	my $final="-";
	if ($flag >= 3 && $flag <= 4) {
		$final = "*";
	}elsif($flag >= 5 && $flag <= 7){
		$final = "**";
	}elsif($flag >= 8 ){
		$final = "***";
	}
	return $final;
}

