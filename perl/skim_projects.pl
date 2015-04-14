#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper ;
use LWP::UserAgent;
use JSON;
use Getopt::Long;

# Example:
# http://api.metagenomics.anl.gov/project?verbosity=full

# metagenome id
my $metagenome_id = undef ;

# mgrast base api url
my $url = "http://api.metagenomics.anl.gov/" ;

# resource name
my $resource = "project" ;

# api parameter
my $options = "?verbosity=full&limit=100";

# submit to ena , default is false
my $submit = 0 ;

# auth key
my $auth = undef ;

GetOptions(
     'metagenome_id=s' => \$metagenome_id ,
     'url=s'  => \$url ,
     'submit' => \$submit,
	 'auth'   => \$auth,
);


# initialise user agent
my $ua = LWP::UserAgent->new;
$ua->agent('EBI Client 0.1');


my $next = join "/" , $url, $resource , $options;

while($next){
	# retrieve data
	print STDERR $next , "\n" ;
	my $response = $ua->get($next);

	unless($response->is_success){
    	 print STDERR "Error retrieving data for $next.\n";
     	# add http error message
     	exit;
	}

	my $json = new JSON;
	my $data = undef;

	# error handling if not json
	eval{
    	 $data = $json->decode($response->content);
		 $next = $data->{next};
	 };

	 if($@){
     	print STDERR "Error: $@\n";
     	exit;
	}

	foreach my $project (@{ $data->{data} } ){
		print join "\t" , $project->{id} , ($project->{metadata}->{ncbi_id} || 'undef') , "\n" ;
	}

}