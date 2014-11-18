use strict;
use warnings;
use Config::Simple;

use Getopt::Long;

use LWP::UserAgent;
use JSON;

use Data::Dumper ;

sub help {
  my $helptext = qq~
~;
  print $helptext;
}



my $HOST      = 'http://api.metagenomics.anl.gov';
my $text      = '';
my $user      = '';
my $pass      = '';
my $token     = '';
my $verbosity = 'full';
my $help      = '';
my $webkey    = '';
my $offset    = '0';
my $limit     = '10';
my $id        = undef;
my $path      = "./" ;
  

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
			 'dir=s' => \$path 
			 );
			 

if ($help) {
  &help();
  exit 0;
}



my $json = new JSON;



my $resource = "metagenome";



my $url = join "/" , $HOST , $resource;
if ($webkey) {
  $url .= "&auth=".$webkey;
}
my $ua = LWP::UserAgent->new;
if ($token) {
  $ua->default_header('user_auth' => $token);
}
if (exists $ENV{'KB_AUTH_TOKEN'}) {
  $ua->default_header('user_auth' => $ENV{'KB_AUTH_TOKEN'});
}




my $next = "http://api.metagenomics.anl.gov/metagenome?limit=$limit&verbosity=full" ;

while($next){

	my $content = $ua->get($next)->content;
	my $data = $json->decode($content) ;
	
	$next = $data->{next};
	
	foreach my $mg (@{ $data->{data} }){
		
		print join "\t" , $mg->{id} , lc($mg->{sequence_type}) ,"\n" ;
		
		my $fname = join "." , $mg->{id} , lc($mg->{sequence_type}) , 'metagenome' ;
		
		open(FILE , ">$path/$fname") or die "Can't open $path/$fname for writing!\n" ;
		print FILE $json->encode($mg) ; 
		close(FILE);
		

		my $error = system("ws-load") ;
		print "ERROR:\t" , $error , "\n" ;

		if ($error){
			my $error = `ws-load Communities.Metagenome $fname $path/$fname -w Data`		
		}		
	}
	
	
#	print Dumper $data ;
	
	print $next , "\n" ;
	exit;
}
