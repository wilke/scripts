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
			 

if ($help) {
  &help();
  exit 0;
}

my $json = new JSON;




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
		elsif ($resource eq "profile") {
			&dump_profile_from_file($file);
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
	elsif ($resource eq "profile"){
		&dump_all_profiles($path)
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

		    if($continue){
			$continue = 0 if ( $continue eq $mg->{id} ) ;
			next ;
		    }

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
      		  my $error =`ws-load Communities.Metagenome $fname $path/$fname -w $workspace_name` ;
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
		&import_into_workspace($f, "$p/$f" , $t ,  $workspace_name);

		
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



sub dump_all_profiles{
	my ($path , $ws_type) = @_ ;
	
	my $next = "http://api.metagenomics.anl.gov/metagenome?limit=$limit&verbosity=mixs";


	# loop through all metagenomes , api call returns paginated results
	while ($next) {

    	my $content = $ua->get($next)->content;
		my $data    = '';
		
		eval{
			$data = $json->decode($content); 
		};
		if ($@){
			print STDERR $content , "\n";
			print STDERR $@ ;
			exit;
		}
    	

		# link to next page
    	$next = $data->{next};

		# Create workspace object for every metagenome in page
		
		
		foreach my $mg ( @{ $data->{data} } ) {

        	# print join "\t", $mg->{id}, lc( $mg->{sequence_type} ), "\n";

        	

			my $mgid = $mg->{id} ;
			
			if($continue){
				$continue = 0 if ( $continue eq $mgid ) ;
				print STDERR "Skipping $mgid\n" ;
				next ;
			}
			
			# Define profiles 	
			my $SEED = {
				name => "SEED",
				type => "taxonomic",
            	url  => "http://api.metagenomics.anl.gov//profile/$mgid/?source=SEED&type=organism&hit_type=all",
				ws_type => "Communities.TaxonomicProfile"
        	};

			my $Subsystems = {
            	name => "Subsystems",
				type => "functional",
            	url  => "http://api.metagenomics.anl.gov//profile/$mgid/?source=Subsystems&type=function&hit_type=all",
				ws_type => "Communities.FunctionalProfile" ,
        	};

        	my $SILVA = {
            	name => "Silva",
            	type => "taxonomic",
            	url  => "http://api.metagenomics.anl.gov//profile/$mgid/?source=SSU&type=organism&hit_type=all",
				ws_type => "Communities.TaxonomicProfile"
        	};
			
			my $profiles = [] ;

		    if ( $mg->{sequence_type} eq "WGS" ) {
				
				# retrieve all profiles in list
				push @$profiles , $SEED , $Subsystems , $SILVA ;
				
			}
			elsif( $mg->{sequence_type} eq "Amplicon" ) {
				# retrieve all profiles in list
				push @$profiles , $SILVA ;
			}
			elsif( $mg->{sequence_type} eq "MT" ) {
				# retrieve all profiles in list
				push @$profiles , $SILVA ;
			}
			else{
				print STDERR "Unknown  metagenome type ". $mg->{sequence_type}." for $mgid\n" ;
			}
			
			foreach my $p (@$profiles){
				
	        	my $fname = join ".", $mg->{id}, lc( $mg->{sequence_type} ), $p->{type} , 'profile';
				
				# time for stats
				my $time_start = time ;
						
		    	my $content = $ua->get($p->{url})->content;
		    	
				my $data ;
				
				eval{
					$data = $json->decode($content); 
				};
				
				if ($@){
					print STDERR "Error: " , $content , "\n";
					print STDERR "Error:" , $p->{url} , "\n" ;
					print STDERR $@ ;
					exit;
				}
			
				# time for stats
				my $time_got_data = time ;
				
				# missing url in profile, adding self referencing url to profile data structure
				$data->{url} = $p->{url} ;
			
			# get metagenome ws object
			my $mgname = join ".", $mg->{id}, lc( $mg->{sequence_type} ),
			'metagenome';
			my $tmp = `ws-get -w $workspace_name $mgname` ;
			unless( $tmp =~ /No object with name/){
			    $data->{metagenomes} = { 
				description => 'parents' ,
				elements    => { 
				    $mgname => { ref => "$workspace_name/$mgname" },
				}
			    };
			}
			
				# Dump json to file
	   		 	open( FILE, ">$path/$fname" )or die "Can't open $path/$fname for writing!\n";
				print FILE $json->encode($data);
				close(FILE);
				
				import_into_workspace($fname , "$path/$fname" , $p->{ws_type} , $workspace_name);
				
				# time for stats
				my $time_load = time ;
				
				# log message
				print join "\t", $mg->{id}, lc( $mg->{sequence_type} ), $p->{name} , $time_start , $time_got_data , $time_load , ($time_got_data - $time_start) , ($time_load - $time_got_data) , "\n";
			}
		
			
		
				
    	}

    	#	print Dumper $data ;

   	 print $next , "\n";
	}

}


sub export_profile{
	my ($mg , $path) = @_ ;
	
	my $mgid 	= $mg->{id} ;
	my $error 	= 0 ;
	
	if($continue){
		$continue = 0 if ( $continue eq $mgid ) ;
		next ;
	}
	
	# Define profiles 	
	my $SEED = {
		name => "SEED",
		type => "taxonomic",
    	url  => "http://api.metagenomics.anl.gov//profile/$mgid/?source=SEED&type=organism&hit_type=all",
		ws_type => "Communities.TaxonomicProfile"
	};

	my $Subsystems = {
    	name => "Subsystems",
		type => "functional",
    	url  => "http://api.metagenomics.anl.gov//profile/$mgid/?source=Subsystems&type=function&hit_type=all",
		ws_type => "Communities.FunctionalProfile" ,
	};

	my $SILVA = {
    	name => "Silva",
    	type => "taxonomic",
    	url  => "http://api.metagenomics.anl.gov//profile/$mgid/?source=SSU&type=organism&hit_type=all",
		ws_type => "Communities.TaxonomicProfile"
	};
	
	# List of profiles and profile parameters
	my $profiles = [] ;
	
	# List for created/dumped profiles for further treatment
	my @profile_file_names ;
    
	# Add specific profile parameters to list, this will be used to download profiles with specified parameters
	if ( $mg->{sequence_type} eq "WGS" ) {
		
		# retrieve all profiles in list
		push @$profiles , $SEED , $Subsystems , $SILVA ;
		
	}
	elsif( $mg->{sequence_type} eq "Amplicon" ) {
		# retrieve all profiles in list
		push @$profiles , $SILVA ;
	}
	elsif( $mg->{sequence_type} eq "MT" ) {
		# retrieve all profiles in list
		push @$profiles , $SILVA ;
	}
	else{
		print STDERR "Unknown  metagenome type ". $mg->{sequence_type}." for $mgid\n" ;
	}
	
	# Download profiles for every parameter set
	foreach my $p (@$profiles){
		
    	my $fname = join ".", $mg->{id}, lc( $mg->{sequence_type} ), $p->{type} , 'profile';
		
		# time for stats
		my $time_start = time ;
				
    	my $content = $ua->get($p->{url})->content;
    	
		my $data ;
		
		
		
		eval{
			$data = $json->decode($content); 
		};
		
		if ($@){
			$error = 1 ;
			my $time_error = time ;
			print STDERR "Error: " , $content , "\n";
			print STDERR "Error:" , $p->{url} , "\n" ;
			print STDERR "Error: " , "Stopped after " , ($time_error - $time_start) , " seconds.\n";
			print STDERR $@ ;
			
			return ( \@profile_file_names , $error) ;
		}
	
		# time for stats
		my $time_got_data = time ;
		
		# missing url in profile, adding self referencing url to profile data structure
		$data->{url} = $p->{url} ;
	

	
		# Dump json to file
	 	open( FILE, ">$path/$fname" )or die "Can't open $path/$fname for writing!\n";
		print FILE $json->encode($data);
		close(FILE);
		
		my $ws_type = "Communities.FunctionalProfile" ;
		$ws_type = "Communities.TaxonomicProfile" if ($p->{type} eq "taxonomic") ;
		
		push @profile_file_names , [$fname , $path , $ws_type] ;
	}
	
	return (\@profile_file_names , $error ) ;
}

sub dump_profile_from_file{
	my ($file,$ids) = @_;
	
	if($file){
		open(FILE , $file) or die "Can't open file $file for reading!\n";
		while(my $line = <FILE>){
			chomp $line ;
			my ($id) = $line =~/^([\w\.]+)/;
			
			if($continue){
				$continue = 0 if ( $continue eq $id ) ;
				print STDERR "Skipping $id\n" ;
				next ;
			}
			
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
		
		
		##### TEST #####
		my $counter = 3 ;
		my $repeat  = 1 ;
		my $wait    = 10 ;
		my $profile_file_names = undef ;
		
		while($repeat and $counter){
    		($profile_file_names , $repeat) = &export_profile($mg , $path) ;
			$counter--;
			if ($repeat){
				print STDERR "Error , waiting $wait seconds for retry.\n" unless($counter) ;
				sleep $wait ;
				$wait = $wait * 4 ;
			}
		}	

		# skip if error aka repeat
		next if $repeat ;

		foreach my $p (@$profile_file_names){ 
			
			my ($f , $path , $workspace_type) = @$p ; 
			&import_into_workspace($f, "$path/$f" , $workspace_type ,  $workspace_name);
		}
		
	}
	
}
