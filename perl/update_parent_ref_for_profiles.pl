use strict;
use warnings;
#use Config::Simple;

use Getopt::Long;

use LWP::UserAgent;
use JSON;

use Data::Dumper ;

sub help {
  my $helptext = qq~
~;
  print $helptext;
}



my $HOST      = 'http://kbase.us/services/communities';
my $text      = '';
my $user      = '';
my $pass      = '';
my $token     = '';
my $verbosity = 'full';
my $help      = '';
my $webkey    = '';
my $offset    = '0';
my $limit     = '100';
my $id        = undef;
my $path      = "./" ;
my $resource  = '';
my $file      = '';
my $continue  = '';
my $workspace_name = "Data" ;
  

GetOptions ( 'user=s' => \$user,
             'pass=s' => \$pass,
             'token=s' => \$token,
             'verbosity=s' => \$verbosity,
             'help' => \$help,
             'webkey=s' => \$webkey,
             'limit=s' => \$limit,
             'offset=s' => \$offset,
             'text=s' => \$text,
	         'id=s' => \$id,
			 'dir=s' => \$path, 
			 'file=s' => \$file,
			 'resource=s' => \$resource ,
			 'continue=s' => \$continue ,
			 'workspace=s' => \$workspace_name,
			 );
		
		
if($workspace_name){
	
	# get all profiles
	
	my @list = `ws-listobj -w $workspace_name -t Communities.TaxonomicProfile` ;
	
	#for every profile
	#check if parent metagenome object exists
	#add ref to parent
	
}	 
			 
			 
			 