
# Create a m8 like hit table from a gto

use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.


use Getopt::Long;


my $verbose 	      = 0 ;
my $nr_records        = 5000 ;
my $id                = 'ChunkedMetagenome';
my $path_and_filename = "./tmp" ;
my $file              = undef   ;
my $json              = new JSON ; 


   

GetOptions (
	'verbose+'   => \$verbose,
	'gto=s'	 	 => \$file,
	'records=i'	 => \$nr_records,
	'filename=s' => \$path_and_filename ,
);

###############################
# Read GTO from file

# Container for lines
my $txt = ''; 

open(GTO , $file) or die "Can't open file $file for reading!" ;
while (my $line = <GTO>) {
	$txt .= $line ;
}
close(GTO);

#####################################
# Create perl data struct from json

my $gto = $json->decode($txt);



foreach my $feature ( @{$gto->{features}} ){
	
	#print Dumper $feature ;

	if (exists $feature->{function} or exists $feature->{organism}){
		print join ("\t" , $feature->{id} , $feature->{function} || 'undef' , $feature->{organism} || 'undef' , $feature->{quality}->{hit_count} || undef ) , "\n" ;
	}
	
}

