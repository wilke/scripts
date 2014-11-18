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


if($file){
	
	if (-f $file){
		if ($resource eq "metagenome"){
			&dump_metagenome_from_file($file);
		}
		else{
			print STDERR "Dumper for $resource not implemented!\n";
		}
	}
	else{
		print STDERR "File $file does not exist!\n";
		exit -1 ;
	}
	
}
else{
	if ($resource eq "metagenome"){
		&dump_all_metagenomes();
	}
	else{
		print STDERR "Dumper for $resource not available!\n";
	}
}

sub dump_all_metagenomes{
	
	my $next = "http://api.metagenomics.anl.gov/metagenome?limit=$limit&verbosity=full";


	# loop through all metagenomes , api call returns paginated results
	while ($next) {

    	my $content = $ua->get($next)->content;
    	my $data    = $json->decode($content);

		# link to next page
    	$next = $data->{next};

		# Create workspace object for every metagenome in page
		foreach my $mg ( @{ $data->{data} } ) {

        	print join "\t", $mg->{id}, lc( $mg->{sequence_type} ), "\n";

        	my $fname = join ".", $mg->{id}, lc( $mg->{sequence_type} ),
          	'metagenome';

			# Dump json to file
   		 	open( FILE, ">$path/$fname" )or die "Can't open $path/$fname for writing!\n";
			print FILE $json->encode($mg);
			close(FILE);

			# Check if command line script is available
			my $error = 1 || system("ws-load --help");


			# Load object from file into workspace
			if ($error) {
      		  my $error =`ws-load Communities.Metagenome $fname $path/$fname -w Data` ;
       		  print STDERR $error;
        	}
    	}

    	#	print Dumper $data ;

   	 print $next , "\n";
	}

}

sub dump_metagenome_from_file{
	my ($file, $ids) = @_ ;
	
	if($file){
		open(FILE , $file) or die "Can't open file $file for reading!\n";
		while(my $line = <FILE>){
			chomp $line ;
			my ($id) = $line =~/^([\w\.]+)/;
			push @$ids , $id ;
		}
		close(FILE)
	}
	
	print Dumper @$ids ;

	
	foreach my $id (@$ids){
		
		my $url = "http://api.metagenomics.anl.gov/metagenome/$id?verbosity=full";
		print $url , "\n";

		# loop through all metagenomes , api call returns paginated results

	    my $content = $ua->get($url)->content;
	    my $mg    = $json->decode($content);
		
    	my ($f ,$p , $t) = &export_metagenome($mg , $path) ;
		&import_into_workspace($f, "$p/$f" , $t);

		
	}
	
};

sub export_metagenome{
	my ($mg , $path ) = @_ ;
	
	print join "\t", $mg->{id}, lc( $mg->{sequence_type} ), "\n";

	my $fname = join ".", $mg->{id}, lc( $mg->{sequence_type} ),'metagenome';

	# Dump json to file
 	open( FILE, ">$path/$fname" )or die "Can't open $path/$fname for writing!\n";
	print FILE $json->encode($mg);
	close(FILE);
	
	return ("$fname" , $path , "Communities.Metagenome") ;
}

sub import_into_workspace{
	my ($object_name , $file_with_path , $workspace_type , $workspace_name) = @_ ;
	
	
	# Check if command line script is available
	my $error = 1 || system("ws-load --help");


	# Load object from file into workspace
	if ($error) {
	  my $error =
		`ws-load $workspace_type $object_name $file_with_path -w $workspace_name`;
	   print STDERR $error;
	}
	
}