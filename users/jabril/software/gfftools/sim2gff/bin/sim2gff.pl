#!/usr/local/bin/perl -w
#
#
# $Id: sim2gff.pl,v 1.1 2003-02-28 17:45:36 jabril Exp $
#
#
use strict;
use Carp;
use Getopt::Std;
use File::Basename;
#
use vars qw($opt_r $opt_x $opt_y $opt_H $opt_f $opt_h);
#
################################################################################
# Package revision string                                                      #
################################################################################
#
my $prg         = basename($0);
my $rev         = "1.01";
my $columns     = 50;
#
my $simfile;
my $outfile;
my $command;
my $alicount;
my @scorearray ;
my $i;
my @tmp=0;
my %sim    ;
#*****
my $_array    ;
my @list;
my $line;
my $score;
my $species1;
my $species2;
my $method;
my $strand;
my $feature;
my $avlen;
my $nmp;
my $begin1;
my $begin2;
my $end1;
my $end2;
my $x1frame;
my $x2frame;
my $y1frame;
my $y2frame;
my $flag = "";
my $linemark;
my $lav;
#
# Man page
#
my $MAN = <<MAN;
NAME

     	$prg (Rev. $rev) converts SIM file into 
	GFF format (for use with gff2psplot and gff2javaplot)

AVAILABILITY

     	Requires perl 5.002

SYNOPSIS

    	$prg [-frxyHh] sim_file

OPTIONS

     -h         print this help text
     -f		output is written to a file named <sim_file>.gff
     -r		interchange the order of sequences (Seq1 on y-axis, Seq2 on x-axis)
     -x	<name>  specify the species name for species1 (default: "Seq1")
     -y	<name>  specify the species name for species2 (default: "Seq2")
     -H 	use the fasta file headers for species labels

EXIT STATUS

     The following perl-like exit status are returned:

     0        Error
     1        Successful completion
 
AUTHOR(S)

     Thomas Wiehe  (twiehe\@imb-jena.de)

CHANGES

     30.04.1999	Steffi Gebauer-Jung (steffi\@imb-jena.de)
     - output strand according new gff format as "+" or "-" instead of 0 or 1	

ACKNOWLEDGMENTS

MAN
#
getopts('frx:y:Hh') && ! defined($opt_h) && $#ARGV==0 || croak($MAN);
$simfile = shift;
#
sub max(){
	my $a = shift;
	my $b = shift;

	if($a>$b){
		return $a;
	}else{
		return $b;
	}
}
#
##count the number of alignments:
#
$command = sprintf("more %s | grep \"a\ {\" | wc -l |",$simfile);
open(PRG,"$command")||croak(sprintf("Cannot count alignments (ERRMSG = %s)\n",$!));
while(<PRG>){
	if(/\b[0-9]+/){
		$alicount = (split)[0];
	}
}
close(PRG);
#
##sort the encountered score values and store in array scorearray:
#
$command = sprintf("more %s | grep \"\ \ s\ \" | ",$simfile);
open(PRG,"$command")||croak(sprintf("Cannot sort alignment scores (ERRMSG = %s)\n",$!));
$i=0;
while(<PRG>){
	if(/\bs\ [0-9]+/){
	 chomp;
	 $i++;
         $tmp[$i] = (split)[1];
	} 
}
close(PRG);
@scorearray = sort { $a <=> $b } @tmp;
#
-e $simfile                    
    	or croak(sprintf("Cannot find %s file (ERRMSG = %s)",$simfile,$!));
open(SIMFILE,"< $simfile")     
    	or croak(sprintf("Cannot open %s file for reading (ERRMSG = %s)",$simfile,$!));
if(defined($opt_f)){
 #@tmp = split(".sim",$simfile);
 #$outfile = sprintf("%s%s",(split(/\//,$tmp[0]))[-1],".gff");
 $outfile = sprintf("%s%s",(split(/\//,$simfile))[-1],".gff");
 open(STDOUT,"> $outfile")
      or croak(sprintf("Cannot open %s file for writing (ERRMSG = %s)",$outfile,$!));
}
$lav=0;
$line=0;
$linemark=0;
printf STDOUT ("## Alignments from sim file %s\n",$simfile);
while(<SIMFILE>){
 chomp;
 $line++;
 if(/^\#\:lav/){
 	$lav++;
 }
 if(/^d\ \{/){	
     $linemark=$line;
     $flag="d";
 }
 if ($line==$linemark+1 && $flag=~"d") {
        @list=split(/\"/,$_);
	@list=split(/\ /,$list[1]);
	@list=split(/\//,$list[0]);
	$method=$list[-1];
	#printf("method: %s\n",$method);
 }
 $species1="Seq1";
 $species2="Seq2";
 if(defined($opt_x)){
   $species1=$opt_x;
 }
 if(defined($opt_y)){
   $species2=$opt_y;
 }
 if(defined($opt_H)){
     if(/^h\ \{/){
      $linemark=$line;
      $flag="h";
     }
     if ($line==$linemark+1 && $flag=~"h") {
        @list=split(/>|\ |\.+/,$_);
	$species1=$list[1];
	#printf("species1: %s\n",$species1);
     }
     if ($line==$linemark+2 && $flag=~"h") {
        @list=split(/>|\ |\.+/,$_);
	$species2=$list[1];
     }
 }
 if(/^s\ \{/){
     $linemark=$line;
     $flag="s";
 }
 if ($line==$linemark+1 && ($flag =~ "s")) {
       @list=split;
       $x1frame=$list[1];
       $x2frame=$list[2];
       #printf("x1: %d\n",$x1frame);
 }
 if ($line==$linemark+2 && ($flag =~ "s")) {
       @list=split;
       $y1frame=$list[1];
       $y2frame=$list[2];
       $feature = "seqbounds";
       if(!defined($opt_r)){
        printf STDOUT ("%s:%s\t%s\t%9s\t%9d:%-9d\t%9d:%-9d\t%.3f\t%s\t%d\t%s\t%s\n",
                  uc($species1),uc($species2),uc($method),$feature,$x1frame,$y1frame,
                  $x2frame,$y2frame,"0.0","+","0","0","##");
       }else{
        printf STDOUT ("%s:%s\t%s\t%9s\t%9d:%-9d\t%9d:%-9d\t%.3f\t%s\t%d\t%s\t%s\n",
                  uc($species2),uc($species1),uc($method),$feature,$y1frame,$x1frame,
                  $y2frame,$x2frame,"0.0","+","0","0","##");
       }
 }
 if(/^a\ \{/) {
 	$flag="a";
        $nmp=0.0;
 }
 if($flag=~"a"){
	    if ( /^(\s*)s/ ) {
	     @list = split;
	     $score = $list[1];
	     $i=0;
	     while($score!=$scorearray[$i]){$i++;}
	     $feature=sprintf("\:%.1f",&max(1.-($alicount-$i)/10.,0.4));
	     $score .= $feature;
	     $feature = "align";
	    }
	    if ( /^(\s*)b/ ) {
             @list = split;
             $begin1 = $list[1];
	     $begin2 = $list[2];
            }
	    if ( /^(\s*)e/ ) {
             @list = split;
             $end1 = $list[1];
             $end2 = $list[2];
	     $avlen = (abs($end1-$begin1+1)+abs($end2-$begin2+1))/2.;
            }
            if ( /^(\s*)l/ ) {
                @list = split;
		if(($list[1]>$list[3]&&$list[2]<=$list[4])||($list[1]<=$list[3]&&$list[2]>$list[4])||$lav==2){
			$strand="-"; #"reverse alignment"
		}else{
			$strand="+"; #"regular alignment"
		}
		$nmp += abs($list[3]-$list[1]+1.)*$list[5]/($avlen*100.);
		if($lav==1){
		 if(!defined($opt_r)){
		  printf STDOUT ("%s:%s\t%s\t%9s\t%9d:%-9d\t%9d:%-9d\t%.3f\t%s\t%d\t%s\t%s%.3f\n",
		   uc($species1),uc($species2),uc($method),$feature,$list[1],$list[2],
		   $list[3],$list[4],$list[5]/100.,$strand,"0",$score,"## cumulative nmp: ",$nmp); #slot "frame" is not used
		 }else{
		  printf STDOUT ("%s:%s\t%s\t%9s\t%9d:%-9d\t%9d:%-9d\t%.3f\t%s\t%d\t%s\t%s%.3f\n",
		   uc($species2),uc($species1),uc($method),$feature,$list[2],$list[1],
		   $list[4],$list[3],$list[5]/100.,$strand,"0",$score,"##cumulative nmp: ",$nmp); #slot "frame" is not used
		 }
		}
		if($lav==2){
		 if(!defined($opt_r)){
		  printf STDOUT ("%s:%s\t%s\t%9s\t%9d:%-9d\t%9d:%-9d\t%.3f\t%s\t%d\t%s\t%s%.3f\n",
		   uc($species1),uc($species2),uc($method),$feature,$list[1],$y1frame+$y2frame-$list[2],
		   $list[3],$y1frame+$y2frame-$list[4],$list[5]/100.,$strand,"0",$score,"## cumulative nmp: ",$nmp); #slot "frame" is not used
		 }else{
		  printf STDOUT ("%s:%s\t%s\t%9s\t%9d:%-9d\t%9d:%-9d\t%.3f\t%s\t%d\t%s\t%s%.3f\n",
		   uc($species2),uc($species1),uc($method),$feature,$y1frame+$y2frame-$list[2],$list[1],
		   $y1frame+$y2frame-$list[4],$list[3],$list[5]/100.,$strand,"0",$score,"##cumulative nmp: ",$nmp); #slot "frame" is not used
		 }
		}
            }
	    if ( /^\}/ ) {
	    	$flag="";
	    }	    
 }
}
close(STDOUT)
        or croak(sprintf("Cannot close %s file (ERRMSG = %s)",$outfile,$!));	
exit();