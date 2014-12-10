#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper ;
use LWP::UserAgent;
use JSON;
use Getopt::Long;
use Net::FTP;

# Global json methods
my $json = new JSON;

# Example:
# http://api.metagenomics.anl.gov/project?verbosity=full

# metagenome id
my $project_id = undef ;

# mgrast base api url
my $url = "http://api.metagenomics.anl.gov/" ;

# resource name
my $resource = "project" ;

# api parameter
my $options = "?verbosity=full";

# submit to ena , default is false
my $submit = 0 ;

# auth key
my $auth = undef ;

my $user 		= undef ;
my $password 	= undef ;
my $ftp_ena     = "webin.ebi.ac.uk";

# verbosity
my $verbose = 0 ;


GetOptions(
     'project=s' => \$project_id ,
     'url=s'  	 => \$url ,
     'submit' 	 => \$submit,
	 'user=s'    => \$user,
	 'password=s'=> \$password,
	 'verbose' 	 => \$verbose,
);


# initialise user agent
my $ua = LWP::UserAgent->new;
$ua->agent('EBI Client 0.1');


my $resource_url = join "/" , $url, $resource , $project_id , $options;


# retrieve data
print STDERR $resource_url , "\n" ;
my $response = $ua->get($resource_url);

unless($response->is_success){
   	 print STDERR "Error retrieving data for $resource_url.\n";
   	# add http error message
   	exit;
}

# json to hash
my $data = &decode($response->content);

# Setup ftp/aspera connection
my $ftp = Net::FTP->new( $ftp_ena, Debug => 1) or die "Cannot connect to $ftp_ena: $@";
$ftp->login($user,$password) or die "Cannot login using $user and $password", $ftp->message;
$ftp->mkdir($project_id) ;
$ftp->cwd($project_id);


foreach my $metagenome (@{ $data->{metagenomes} } ){
	#print Dumper $metagenome ;

	print join "\t" , $data->{id} , ($metagenome->[0] || 'undef') , "\n" ;
	
	my $resource 	= "download" ;
	my $stage_name  = "upload" || "preprocess.passed" ;
	
	my $response = $ua->get( join "/" , $url , $resource , $metagenome->[0] );
	
	unless($response->is_success){
	   	 print STDERR "Error retrieving data for $resource_url.\n";
	   	# add http error message
	   	exit;
	}


	

	my $stages = &decode($response->content);
	
	foreach my $stage ( @{$stages->{data}} ){
	
		if ($stage->{stage_name} eq $stage_name){
			print join "\t" , $stage->{stage_name} , $stage->{url} , "\n"  if ($verbose);
			
			# get sequences from MGRAST
			my $call = "curl \"" . $stage->{url} . "\">" . $stage->{file_name} ;  
			
			print $call , "\n" if ($verbose) ; 
			my $out = `$call` unless(-f $stage->{file_name} ) ;
			
			unless(-f $stage->{file_name} ){
				print STDERR "Error: Missing file " . $stage->{file_name} . "\n" ;
			}
			else{
				print STDERR ($out || "success for $call"), "\n" ;
			}
			# upload to ENA
			
			#my $call ="ftp -in <<EOF\nopen $ftp_ena\nuser $user:$password\nls\nbye\nEOF\echo Done\n";
			
			
		 
		   $ftp->put($stage->{file_name});
		   print $ftp->ls ;
		   #$ftp->cwd("/pub") or die "Cannot change working directory ", $ftp->message;
		   #$ftp->get("that.file") or die "get failed ", $ftp->message;
		   #$ftp->quit;
			
		}
	}
	
	

}




sub decode{
	my($json_string) = @_;
	

	my $data = undef;
	
	eval{
	   	 $data = $json->decode($json_string);
		};

	if($@){
	     print STDERR "Error: $@\n";
		 print STDERR $json_string;
	     exit;
	}
	
	return $data ;
}