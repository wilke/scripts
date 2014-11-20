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
			 );
			 

if ($help) {
  &help();
  exit 0;
}



my $json = new JSON;


opendir(DIR, $path) || die;
while(readdir DIR) {
	my $mgfile = $_ ;
	if ($mgfile =~ /\.metagenome$/){
		print "$path/$_\n";
		create_key_list("$path/$mgfile") ;
	}

}
closedir DIR;

sub create_key_list{
	my ($file) = @_;
	
	open(FILE , $file) ;
	
	my $data = <FILE> ;
	my $mg   = $json->decode($data) ;
		
	print Dumper $mg ;
	
	foreach my $keyA ( keys( %{$mg->{metadata}}) ) {
		
		foreach my $keyB ( keys( %{$mg->{metadata}->{$keyA} } ) ){
			
			if ($keyB eq "data"){
				foreach my $keyC ( keys( %{$mg->{metadata}->{$keyA}->{$keyB} } )){
					print join "\t" , $keyA , $keyC ;
					print "\n" ;
				}
			}
			else{
				print join "\t" , $keyA , $keyB ;
				print "\n" ;
			}
		}
		
	}
	
	foreach my $key ( keys ( %{$mg->{mixs}} ) ){
		print join "\t", "mixs", $key ;
		print "\n";
	}
	
		
	close FILE;
	
}