#!/usr/local/bin/perl -w

# Issue warnings about suspicious programming.
use warnings 'all';

# Must declare and initialize all variables
use strict;

# be prepare for command-line options/arguments
use Getopt::Std;

# Use the code module that contains MOBY Service.
use MOBY::Client::Central;

sub help {
    return <<"END_HELP";
Description: Register an object in Moby Central
  Usage:
    
    registerService.pl [-h] -x {Moby Central}
    -h help
	-x MOBY Central: Chirimoyo, Mobydev, Inab or BioMoby
	<1> or Chirimoyo
	<2> or Mobydev
	<3> or Inab
	<4> or BioMoby
	
	Examples using some combinations:
	perl registerObject.pl -x 2

END_HELP

}

BEGIN {
	
    # Determines the options with values from program
    use vars qw/$opt_h $opt_x/;
    
    # these are switches taking an argument (a value)
    my $switches = 'hx';
    
    # Get the switches
    getopt($switches);
    
    # If the user does not write nothing, skip to help
    if (defined($opt_h) || !defined($opt_x)){
	print STDERR help;
	exit 0;
    }
    
}

# MOBY Central configuration

# Default registry server is Chirimoyo in Malaga

my $MOBY_URI    = $ENV{MOBY_URI}    ='http://moby-dev.inab.org/MOBY/Central';
my $MOBY_SERVER = $ENV{MOBY_SERVER} ='http://moby-dev.inab.org/cgi-bin/MOBY-Central.pl';

if (defined($opt_x)) {
    # Delete spaces
    $opt_x =~ s/\s//g;
    
    # Assign the MOBY Server and MOBY URI
    if (($opt_x == 1) || ($opt_x eq 'Chirimoyo')) {
	$MOBY_URI    = $ENV{MOBY_URI}    = 'http://chirimoyo.ac.uma.es/MOBY/Central';
	$MOBY_SERVER = $ENV{MOBY_SERVER} = 'http://chirimoyo.ac.uma.es/cgi-bin/MOBY-Central.pl';
    }
    elsif (($opt_x == 2) || ($opt_x eq 'Mobydev')) {
	$MOBY_URI    = $ENV{MOBY_URI}    = 'http://moby-dev.inab.org/MOBY/Central';
	$MOBY_SERVER = $ENV{MOBY_SERVER} = 'http://moby-dev.inab.org/cgi-bin/MOBY-Central.pl';
    }
    elsif (($opt_x == 3) || ($opt_x eq 'Inab')) {
	$MOBY_URI    = $ENV{MOBY_URI}    = 'http://www.inab.org/MOBY/Central';
	$MOBY_SERVER = $ENV{MOBY_SERVER} = 'http://www.inab.org/cgi-bin/MOBY-Central.pl';
    }
    elsif (($opt_x == 4) || ($opt_x eq 'BioMoby')) {
	$MOBY_URI    = $ENV{MOBY_URI}    = 'http://mobycentral.icapture.ubc.ca/MOBY/Central';
	$MOBY_SERVER = $ENV{MOBY_SERVER} = 'http://mobycentral.icapture.ubc.ca/cgi-bin/MOBY05/mobycentral.pl';
    }
    else {
	print STDERR help;
	exit 0;
    }
}
else {
    print STDERR help;
    exit 0;
}

# URI
$::authURI = 'genome.imim.es';

# Contac e-mail
$::contactEmail = 'akerhornou@imim.es';

my $objectName = "Ace_Text";
my $objectDescription = "data format for assembly information";

print STDERR "registrying object $objectName at registry, $MOBY_URI...\n";

# Connect to MOBY-Central registries for searching.
my $Central = MOBY::Client::Central->new(
					 Registries => {mobycentral => {URL => $MOBY_SERVER, URI => $MOBY_URI}}
					 );

# The new MOBY Service Instance is registered.
my ($REG) = $Central->registerObject(
				     objectType    => $objectName,
				     description   => $objectDescription,
				     authURI       => $::authURI,
				     contactEmail  => $::contactEmail ,
				     Relationships => {
					 ISA	=> [
						    ['text_formatted', ""]
						    ],
						}
				     );

# Check if the result has been registered successfully.
if ($REG->success) {
    # The result is valid.
    print "The $objectName object has been registered in $opt_x successfully: ", $REG->success, "\n";
} else {
    # The result is valid.
    print "The $objectName object has failed: ", $REG->message,"\n"; 
}
