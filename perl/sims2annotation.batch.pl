use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.
use LWP::UserAgent ;
use HTTP::Request::Common;
use DB_File ; # for local Berkeley DB

use Getopt::Long;


my $file 		= undef ;
my $verbose 	= 0 ;
my $source 		= undef ;
my $format  	= undef ;
my $base_url 	= "http://api.metagenomics.anl.gov/m5nr" ;
my $dbfile      = undef ;
my $batch_size  = 100 ;

GetOptions (
	'sims=s' 	=> \$file,
	'source=s'  => \$source,
	'verbose+'  => \$verbose,
	'format=s'  => \$format,
	'url=s'     => \$base_url,
	'dbfile=s'  => \$dbfile,
	'batch=i'   => \$batch_size,
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
 
# Berkeley DB
my $db = undef ;
my %hash;

if ($dbfile and -f $dbfile) {
	$db = tie %hash, 'DB_File', $dbfile, O_CREAT|O_RDWR, 0666, $DB_HASH or die "Cannot open $dbfile: $!\n" ; 
}

 
# List of sources from M5NR
my $sources = get_sources(); 


#############################
# Parameter checking 
#############################

unless($sources){
	print STDERR "Can't get source list from M5NR, check connection!\n";
	# exit;
}

# Missing file name
unless($file){
	print STDERR "No file given!\n" ;
	exit;
}

# Missing source name
unless($source){
	print STDERR "No source name provided!\n";
	print STDERR "Sources:\t" , (join "," , (keys %$sources)) , "\n" ;
	exit;
}




my @keys = keys %hash ;
print STDERR , "DB has " . scalar (@keys) . " entries.\n" ;
print STDERR "Example keys are " , join "\t" , $keys[0..5] , "\n" ;

exit;


open(SIMS , $file) or die "Can't open file $file!" ;

# flag for current read block
my @batch ;
# set of md5s for current read
my $md5set= {} ;


# m8: query, subject, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id


print STDERR "Reading SIMS file.\n" ;

while( my $line = <SIMS>){
	
	# GF8803K01A004I_1_134_-  db0bbf5d776a54052c7a5eab36e9e052        80.00   30      6       0       10      39      192     221     4.4e-07 53.0
	# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
	
	chomp $line ;
	my ($read , $md5 , @remainder) = split "\t" , $line ;
	
	# Set batch
	push @batch , [$read , $md5 , @remainder] ;
	# Create md5 query set
	$md5set->{$md5}++ ;
	
	
	if (scalar @batch >= $batch_size){
		
		print STDERR "Processing ".scalar @batch." lines with " . scalar (keys %$md5set) . " md5s.\n" if ($verbose > 2) ;
		
		#process sims for read
		# .....
		
		my $start = time ;
		print STDERR join "\t" , (scalar @batch) , scalar (keys %$md5set) if (@batch);
		my $mapping = [] ;
		
		if($db){
			$mapping = &query_berkeley_db( [ keys %$md5set] ) if (keys %$md5set);
		}
		elsif($base_url){
			$mapping = &query_m5nr( [ keys %$md5set] ) if (keys %$md5set);
		}
		else{
			print STDERR "Not implemented.\n" ;
		}
		
		my $stop = time ;
		print STDERR "\t" , ($stop - $start) , "\n" if (@batch);
		
		my $md5hash = {} ;
		
		# md5 hash for fast lookup and printing
		map { push @{$md5hash->{$_->{md5}}} , $_ } @$mapping ;
		
		print_sims(\@batch , $md5hash);
		
		

		
		
	}
	
	
	
}


close(SIMS);	
			
	
sub print_sims{
	my ($batch , $md5hash) = @_ ;
	
	while(my $entries = shift @$batch){
		
		my $read = shift @$entries ;
		my $md5  = shift @$entries ;
		
		foreach my $md5entry (@{$md5hash->{ $entries->[1 ]} }){
			
			if ($format eq 'expanded'){
	 	   
			   # expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
		       print join ("\t" ,   $md5 , $read ,  $entries->[0] , $entries->[1] , $entries->[8] , ($md5entry->{function} || 'undef') ,  
			   $md5entry->{organism} , $md5entry->{$source} , ($md5entry->{ncbi_tax_id} || '') ), "\n" ; 
		   }
		   else{
		   
			   print join ("\t" , $read ,  $md5, ($md5entry->{function} || '') , $md5entry->{organism} , 
			   @$entries) , "\n" ;   
		   }
			
		}  
   }
}	
			
sub query_m5nr{
	my ($md5s , $sources , $versions) = @_ ;
	
	# {"source":"InterPro","data":["000821a2e2f63df1a3873e4b280002a8","15bf1950bd9867099e72ea6516e3d602"]}

	
	# body for query
	my $request = { 
		source => $source ,
		version => '10' ,
		limit => '1000' ,
		data   => $md5s
	};

	# response from query
	my $md52annotation = undef ;
	
	my $body = $json->encode($request);
	
	
    my $response = $ua->post( $base_url.'/md5' , Content => $body );
	
	# print STDERR Dumper $body ;
 
    if ($response->is_success) {
        #print $response->decoded_content;  # or whatever
		
		my $tmp = $json->decode( $response->decoded_content ) ;
		 $md52annotation = $tmp->{data} ;
		 # print STDERR Dumper $tmp ;
    }
    else {
        die $response->status_line;
    } 

	return $md52annotation ;
}			
	
sub query_berkeley_db{
	my ($md5s , $sources , $versions) = @_ ;
	
	# {"source":"InterPro","data":["000821a2e2f63df1a3873e4b280002a8","15bf1950bd9867099e72ea6516e3d602"]}

	


	# response from query
	my $md52annotation = undef ;
	
	foreach my $md5 (@$md5s){
	
		unless($hash{$md5}){
			print STDERR "No entry for $md5\n";
			next;
		}
	
		foreach my $line (split "\n" , $hash{$md5}){
			my ($md5 , $id , $func , $org , $source ) = split "\t" , $line ;
	
			 push @{$md52annotation} ,  { 
				 						md5 => $md5 ,
		 								function => $func ,
										organism => $org ,
										source => $source ,
										ncbi_tax_id => undef ,
									} ;
		}# print STDERR Dumper $tmp ;
	}
    
	return $md52annotation ;
}
	
	
			
sub get_sources{
	
	my $sources = undef ;
	
	my $response = $ua->get( $base_url.'/sources');
    if ($response->is_success) {
        #print $response->decoded_content;  # or whatever
		
		my $tmp = $json->decode( $response->decoded_content ) ;
		 map { $sources->{$_->{source}} = $_ }  @{$tmp->{data}} ;
		 # print STDERR Dumper $tmp ;
    }
    else {
        die $response->status_line;
    } 
	
	return $sources ;
}			
			