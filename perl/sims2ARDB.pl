use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.
use LWP::UserAgent ;
use HTTP::Request::Common;


use Getopt::Long;


my $file 		= undef ;
my $verbose 	= 0 ;
my $source 		= undef ;
my $format  	= undef ;
my $base_url 	= "http://api.metagenomics.anl.gov/m5nr"

GetOptions (
	'sims=s' 	=> \$file,
	'source=s'  => \$source,
	'verbose+'  => \$verbose,
	'format=s'  => \$format,
	'url=s'     => \$base_url,
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
 
# List of sources from M5NR
my $sources = get_sources(); 

#############################
# Parameter checking 
#############################

unless($sources){
	print STDERR "Can't get source list from M5NR, check connection!\n";
	exit;
}

# Missing file name
unless($file){
	print STDERR "No file given!" ;
	exit;
}

# Missing source name
unless($source){
	print STDERR "No source name provided!\n";
	print STDERR "Sources:\t" , (join "," , (keys %$sources)) , "\n" ;
	exit;
}








open(SIMS , $file) or die "Can't open file $file!" ;

# flag for current read block
my $current_read = '' ;
# set of md5s for current read
my $md5hash = {} ;


# m8: query, subject, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id


print STDERR "Reading SIMS file.\n" ;

while( my $line = <SIMS>){
	
	# GF8803K01A004I_1_134_-  db0bbf5d776a54052c7a5eab36e9e052        80.00   30      6       0       10      39      192     221     4.4e-07 53.0
	# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
	
	chomp $line ;
	my ($read , $md5 , @remainder) = split "\t" , $line ;
	
	if ($read ne $current_read){
		
		print STDERR "Processing read $current_read (" . scalar (keys %$md5hash) . ")\n" if ($verbose > 2) ;
		
		#process sims for read
		# .....
		
		my $start = time ;
		print STDERR join "\t" , $current_read , scalar (keys %$md5hash) if ($current_read);
		my $mapping = &query_m5nr( [ keys %$md5hash] ) if (keys %$md5hash);
		my $stop = time ;
		print STDERR "\t" , ($stop - $start) , "\n" if ($current_read);
		
		if ($mapping and @{$mapping}) {
			
			#sort { $md5hash->{$a->{md5}}->[9] <=>  $md5hash->{$b->{md5}}->[9] } @{$mapping}
			
			#foreach my $entry (@{$mapping}){
			foreach my $entry ( sort { $md5hash->{$b->{md5}}->[9] <=>  $md5hash->{$a->{md5}}->[9] } @$mapping ){
				if ($format eq 'expanded'){
					# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
					print join "\t" ,   $entry->{md5} , $current_read  , $md5hash->{ $entry->{md5} }->[0] , $md5hash->{ $entry->{md5} }->[1] , $md5hash->{ $entry->{md5} }->[8] ,
					     , ($entry->{function} || 'undef') ,  $entry->{organism} , $source , ($entry->{ncbi_tax_id} || '') , @{$md5hash->{ $entry->{md5} }} , "\n" ;
				}
				else{
					print join "\t" , $current_read ,  $entry->{md5} , ($entry->{function} || '') , $entry->{organism} , @{$md5hash->{ $entry->{md5} }} , "\n" ;
				}
						
			}
	
		}
		
		# reset for new read
		$current_read = $read ;
		$md5hash = {} ;
		
		
	}
	
	$md5hash->{$md5} = \@remainder ;
	
}


close(SIMS);	
			
			
			
sub query_m5nr{
	my ($md5s , $sources , $versions) = @_ ;
	
	# {"source":"InterPro","data":["000821a2e2f63df1a3873e4b280002a8","15bf1950bd9867099e72ea6516e3d602"]}

	
	# body for query
	my $request = { 
		source => 'ITS' ,
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
			