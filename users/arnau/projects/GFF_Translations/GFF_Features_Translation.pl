#!/usr/local/bin/perl -w

# To do
# * Parse the gene systematic identifier
# * GFF Parsing in a different package

# Issue warnings about suspicious programming.
use warnings 'all';

# Must declare and initialize all variables
use strict;

# be prepare for command-line options/arguments
use Getopt::Std;

use Data::Dumper;

# Bioperl
use Bio::SeqIO;
use Bio::SeqFeature::Generic;
use Bio::Location::Simple;
use Bio::Location::Split;

sub help {
return <<"END_HELP";
Description: Translate Features in GFF format
Usage:

    promoter_extraction.pl [-h] -s {Sequence in FASTA format} -f {Features in GFF format}
	-h help
	-s Sequence in FASTA format
	-f Features in GFF format

Examples using some combinations:
	GFF_Features_Translation.pl -s AC005155.fa -f AC005155.geneid.gff

END_HELP

}

BEGIN {

    use vars qw /%opts/;
    
    # these are switches taking an argument (a value)
    my $switches = 'hf:s:';
    
    # Get the switches
    getopts($switches, \%opts);
    
    # If the user does not write nothing, skip to help
    if (defined($opts{h}) || !defined($opts{f}) || !defined($opts{s})){
	print help;
	exit 0;
    }
    
}

my $_debug = 0;

my $seqfile;
my $featurefile;

defined $opts{f} and $featurefile      = $opts{f};
defined $opts{s} and $seqfile          = $opts{s};

# The sequence object factory

my $sin  = Bio::SeqIO->new(
			   -file   => $seqfile,
			   -format => 'fasta'
			   );

# The feature object factory

my $fin  = Bio::SeqIO->new(
			   -file   => $featurefile,
			   -format => 'feature'
			   );

# The peptide sequence factory

my $sout = Bio::SeqIO->new(
			   -format => 'fasta'
			   );

print STDERR "processing the GFF file...\n";

my $featuresPerSeqId = parse_gff ($featurefile);

print STDERR "processing done.\n";

print STDERR "processing the sequence fasta file\n";

while ( my $seqobj = $sin->next_seq() ) {
    if ($_debug) {
	print STDERR "processing sequence ",$seqobj->id," first 10 bases ",$seqobj->subseq(1,10),"\n";
    }
    
    my $features = $featuresPerSeqId->{$seqobj->id};
    
    if ((defined $features) && (@$features > 0)) {
	foreach my $f (@$features) {
	    $f->attach_seq ($seqobj);
	    my $splicedseq = $f->spliced_seq();
	    my $pepobj     = $splicedseq->translate();
	    if (defined $pepobj) {
		
		print STDERR "writing out translation for " . $pepobj->id . "\n";
		
		$sout->write_seq($pepobj);
	    }
	    else {
		print STDERR "Error, can't translate feature!\n";
	    }
	}
	
    }
    else {
	print STDERR "No features for sequence, " . $seqobj->id . "\n";
    }    
}

print STDERR "processing done.\n";

##
# End
##


sub parse_gff {
    my ($featurefile) = @_;
    my $features;
    
    open GENEID, "$featurefile" or die "can't open gff file, $featurefile!\n";

    my @features = ();
    my $seqName = undef;
    
    while (<GENEID>) {
	next if /^##/;
	my $line = $_;
	chomp $line;
	
	if ($_debug) {
	    print STDERR "new line : $line";
	}
	
	# extracting the number of exons for the current gene
	
	if ($line =~ /# Gene \d+\s*\(\w+\)\. (\d+) exons\..+/) {
	    
	    my $nb_exons = $1;
	    my $i = 1;
	    
	    if ($_debug) {
		print STDERR "new gene of $nb_exons exons found\n";
	    }
	    
	    # CDS locations
	    my $splitlocation = new Bio::Location::Split();
	    my $codon_start   = undef;
	    my $geneName      = "unknown";

	    # build the cds feature by joining the exon together
	    
	    while ($i <= $nb_exons) {
		$line = <GENEID>;
		# remove the white spaces just keep the tabulations
		$line =~ s/ //g;
		
		if ($_debug) {
		    print STDERR "feature line : $line\n";
		}
		
		$line =~ /^([^\t]+)\t+(\S+)\t+(\w+)\t+(\d+)\t+(\d+)\t+(\S+)\t+(\+|-)\t+(\d+)\t+.+/;
		my $seqName_tmp = $1;
		my $nameFeature = $3;
		my $start       = $4;
		my $end         = $5;
		my $strand      = 1;
		if ($7 =~ /-/) {
		    $strand = -1;
		}
		my $frame       = $8;
		# parsing problem when the strand is "-", can not get the frame in that case !!!
		# so substitute - by + to make the parsing work
		if (not defined $frame) {
		    $line =~ s/-/\+/g;
		    $line =~ /(\w+)\t+(\S+)\t+(\w+)\t+(\d+)\t+(\d+)\t+(\S+)\t+(\+|-)\t+(\d+)\t+.+/;
		    $frame = $8;
		}
		# specify the frame for the first exon, which might not start with a MET
		if (($strand==1 && $i==1) || ($strand==-1 && $i==$nb_exons)) {
		    if ($frame =~ /0/) {
			$codon_start = 1;
		    }
		    elsif ($frame =~ /1/) {
			$codon_start = 2;
		    }
		    elsif ($frame =~ /2/) {
			$codon_start = 3;
		    }
		}

		# parse the geneName...
		
		if (not defined $seqName) {
		    $seqName = $seqName_tmp;
		}
		elsif ($seqName ne $seqName_tmp) {

		    print STDERR "Adding " . @features . " features to sequence, $seqName\n";

		    $features->{$seqName} = [ @features ];
		    @features = ();
		    $seqName  = $seqName_tmp;
		}
		
		my $sublocation = new Bio::Location::Simple (
							     -start  => $start,
							     -end    => $end,
							     -strand => $strand
							     );
		$splitlocation->add_sub_Location ($sublocation);
		
		$i++;
	    }
	    
	    # build the feature object

	    print STDERR "instanciating feature object...\n";
	    
	    my $feature = new Bio::SeqFeature::Generic (
							-location     => $splitlocation,
							-primary      => 'CDS',
							-display_name => "$geneName",
							);
	    $feature->add_tag_value ('codon_start', $codon_start);

	    print STDERR "instanciation done.\n";

	    push (@features, $feature);
	}
	else {
	    if ($_debug) {
		print STDERR "next execution shouldn't occur\n";
	    }
	}
    }
    
    print STDERR "Adding " . @features . " features to sequence, $seqName\n";
    $features->{$seqName} = [ @features ];

    close GENEID;
    
    return $features;
    
}