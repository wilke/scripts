#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Data::Dumper;
use Getopt::Long;
use LWP::UserAgent ;
use HTTP::Request::Common;

my $in_file 	= undef ;
my $out_file 	= undef ;
my $text 		= undef ;
my $verbose 	= 0 ;
my $debug   	= 0 ;

GetOptions ( 
	'input=s'	=> \$in_file,
	'output=s'  => \$out_file,
	'text=s'    => \$text,
	'verbose'   => \$verbose,
	'debug+'    => \$debug,
);


print STDERR "Checking for output name.\n" if ($verbose);

if($out_file){
	
	print STDERR "Writing text to file\n" if ($verbose);
	open(FILE , ">$out_file") or die "Can't open $out_file for writing!\n" ;
		print FILE ($text || "no text to dump into file specified on the command line.\n") ;
	close(FILE);
}
else{
		print STDERR "No output file name given. Please use -output FILENAME !\n"
}

	
	