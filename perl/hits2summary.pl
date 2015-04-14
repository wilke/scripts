#
#  hits2summary.pl
#  scripts
#
#  Created by Andreas Wilke on 2015-03-12.
#  Copyright 2015 Andreas Wilke. All rights reserved.
#

# Input is a expanded sims file from sims2annotation -> sims2hits
# Input file has to be sorted on the column for whoch the summary will be created , low memory version

use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.
use LWP::UserAgent ;
use HTTP::Request::Common;


use Getopt::Long;


my $file 		= undef ;
my $verbose 	= 0 ;
my $source 		= undef ;
my $format  	= undef ;
my $type        = undef ;
my $acolumn      = undef ;
my $ecolumn      = undef ;
my $base_url 	= "http://api.metagenomics.anl.gov/m5nr" ;
my $source_from_options = undef ;


GetOptions (
	'sims=s' 	=> \$file,
	'source=s'  => \$$source_from_options, 	# overwrite existing source tag 
	'verbose+'  => \$verbose,
	'format=s'  => \$format,				# format of input sims file
	'url=s'     => \$base_url,
	'type=s'    => \$type, 					# hit type for output
	'annotation=i'  => \$acolumn,			# column for which summary will be created , column # start at 1
	'evalue=i' 		=> \$ecolumn			# column with evalues , column # start at 1
	);

#################################
# Initialize
#################################

# LWP
my $ua = LWP::UserAgent->new();
$ua->agent('Sims2Source 0.1'); 
#$ua->timeout(1000);
$ua->env_proxy;

# JSON
my $json = new JSON ;  
 
 
unless($acolumn){
	print STDERR "Need column number to create summary.\n" ;
	exit;
}
$acolumn-- ;

$ecolumn-- if $ecolumn ;
 
# flag for current block 
my $current = '' ;
# all entries for a block
my $set 	= {} ; 
my $block   = {} ;

# m8: query, subject, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id


print STDERR "Reading SIMS file $file.\n" ;
open(SIMS , "$file") or die "Can't open file $file for reading!" ;

while( my $line = <SIMS>){
	
	# GF8803K01A004I_1_134_-  db0bbf5d776a54052c7a5eab36e9e052        80.00   30      6       0       10      39      192     221     4.4e-07 53.0
	# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
	
	chomp $line ;
	my @entry = split "\t" , $line ;
	
	if ( $entry[$acolumn] ne $current){
		# Create summary for block
		
		&summary($block) if ($current);
		
		
		# Set current to new block
		$current = $entry[$acolumn] ;
	
		# reset for new block
		$block = {} ;
	}
 
	
	
	
	push @{$block->{$entry[$acolumn]}} , {
		read => $entry[1] , 
		md5 => $entry[0] , 
		function => $entry[5] , 
		organism => $entry[6] , 
		tax_id => ($entry[8] || undef) ,
		source => $entry[7]    ,
		identity => $entry[2] , 
		length => $entry[3] , 
		mismatch => undef , 
		gaps => undef , 
		query_start => undef , 
		query_end => undef ,
		subject_start => undef , 
		subject_end => undef , 
		evalue => (defined $ecolumn ? $entry[$ecolumn] : $entry[4] ) , 
		score => undef } ;
	
 
}
&summary($block) ;






sub summary{
	my ($block) = @_ ;
	
	
	#rint Dumper $block  if $current;
	
	foreach my $key (keys %$block) {
		
		print join ("\t " , $key , scalar @{$block->{$key}} ) , "\n" ;
		
	}
	
}