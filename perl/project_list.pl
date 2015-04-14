#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper ;
use LWP::UserAgent;
use JSON;
use Getopt::Long;

# Global json methods
my $json = new JSON;

# Example:
# http://api.metagenomics.anl.gov/project?verbosity=full

# metagenome id
my $project_id = undef ;

# mgrast base api url
my $url = "http://api.metagenomics.anl.gov/" ;

# resource name
my $resource = "metagenome" ;

# api parameter
my $options = "?verbosity=metadata&limit=500";

# submit to ena , default is false
my $submit = 0 ;

# auth key
my $auth = undef ;

# ENA
my $user 		= "Webin-115" ;
my $password 	= "03NjBQ6H8" ;
my $ftp_ena     = "";

# verbosity
my $verbose = 0 ;

GetOptions(
     'project=s' => \$project_id ,
     'url=s'  	 => \$url ,
     'submit' 	 => \$submit,
	 'auth=s'    => \$auth,
	 'verbose' 	 => \$verbose,
);


# initialise user agent
my $ua = LWP::UserAgent->new;
$ua->agent('EBI Client 0.1');


my $resource_url = join "/" , $url, $resource , $options;





my $list = {} ;
my $next = $resource_url;

print STDERR $next , "\n" ;

while($next){
	
	# retrieve data
	
	my $response = $ua->get($next);

	unless($response->is_success){
	   	 print STDERR "Error retrieving data for $next.\n";
	   	# add http error message
	   	exit;
	}

	# json to hash
	my $data = &decode($response->content);
	


	# project ID , PI Email , PI Firstname , PI lastname , sequence_type , biom , #metagenomes
	
	
	foreach my $metagenome (@{ $data->{data} } ){
		#print Dumper $metagenome ;
		#print join "\t" , $metagenome->{id} , ($metagenome->{biome} || 'undef') , "\n" ;
		
		#print Dumper $metagenome , "\n" ;
		my $prjid = $metagenome->{project}->[0] ;
		
		$list->{ $prjid }->{ "# metagenomes"}++ ;
		$list->{ $prjid }->{biome}->{ ($metagenome->{metadata}->{sample}->{data}->{biome} || "unknown" )}++ ;
		$list->{ $prjid }->{PI}  = join " " , ($metagenome->{metadata}->{project}->{data}->{PI_firstname} || "unkown firstname") ,
								   ( $metagenome->{metadata}->{project}->{data}->{PI_lastname} || "unknow lastname") ;
								   $list->{ $prjid }->{Email}  = $metagenome->{metadata}->{project}->{data}->{PI_email} || "unknown" ;
								   $list->{ $prjid }->{sequence_type}->{ ($metagenome->{sequence_type} || "unknown") }++ ;
	}
	
	
	$next = $data->{next};
	print STDERR $next ;
}


# print list

foreach my $prj (keys %$list){
	
	print join "\t" , $prj ,
		$list->{ $prj }->{ "# metagenomes"} ,
		(join ";" , keys %{ $list->{ $prj }->{ biome } }),
		$list->{ $prj }->{ PI },
		($list->{ $prj }->{ Email } || "todo" ),
		(join ";" , keys %{$list->{ $prj }->{sequence_type}} ) , "\n" ;
}	



sub decode{
	my($json_string) = @_;
	

	my $data = undef;
	
	eval{
	   	 $data = $json->decode($json_string);
		};

	if($@){
	     print STDERR "Error: $@\n";
	     exit;
	}
	
	return $data ;
}