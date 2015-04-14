
##############################################
# Compress read similarites into single hits
#############################################

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
my $type        = undef ;
my $base_url 	= "http://api.metagenomics.anl.gov/m5nr" ;
my $source_from_options = undef ;

GetOptions (
	'sims=s' 	=> \$file,
	'source=s'  => \$$source_from_options, 	# overwrite existing source tag 
	'verbose+'  => \$verbose,
	'format=s'  => \$format,				# format of input sims file
	'url=s'     => \$base_url,
	'type=s'    => \$type, 					# hit type for output
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
 


open(SIMS , $file) or die "Can't open file $file!" ;

# flag for current read block
my $current_read = '' ;

# set of entries/hits for current  read
my @block ;


# m8: query, subject, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id


print STDERR "Reading SIMS file.\n" ;

while( my $line = <SIMS>){
	
	# GF8803K01A004I_1_134_-  db0bbf5d776a54052c7a5eab36e9e052        80.00   30      6       0       10      39      192     221     4.4e-07 53.0
	# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
	
	chomp $line ;
	
	my ($md5 ,$read , $identity , $length , $evalue , $function , $organism , $source , 
	$tax_id , $mismatch , $gaps , $q_start , $q_end , $s_star , $s_end , $score ) ;
	 
	if ($format eq 'expanded'){
		
		# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
		
		($md5 , $read , $identity , $length , $evalue , $function , $organism , $source , $tax_id) = split "\t" , $line ;
	}
	elsif ($format eq 'm8'){

		# 0 	query name
		# 1 	subject name
		# 2 	percent identities
		# 3 	aligned length
		# 4 	number of mismatched positions
		# 5 	number of gap positions
		# 6 	query sequence start
		# 7 	query sequence end
		# 8 	subject sequence start
		# 9 	subject sequence end
		# 10 	e-value
		# 11 	bit score

		# m8: query, subject, identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
	}
	else{
		# m8: query, subject, function , organism , identity, length, mismatch, gaps, q_start, q_end, s_start, s_end, evalue, bit_score
		($read , $md5 , $function , $organism , $identity , $length , $mismatch , $gaps , $q_start , $q_end , $s_star , $s_end , $evalue , $score ) = split "\t" , $line ;
		
	}
	
	
	if ($read ne $current_read){
		
	
		print STDERR "Processing read $current_read (" . scalar @block . ")\n" if ($verbose > 2) ;
		
		#process sims for read
		# .....
		
		my $start = time ;
	
		if($current_read){
			
			if ($type eq 'first'){
				
				# best/first hit in block
				my $hit = $block[0] ;
			
				# expanded: md5|query, fragment|subject, identity, length, evalue, function, organism, source, tax_id
				print join ("\t" , $hit->{md5} , $hit->{read} , $hit->{identity} , $hit->{length} , $hit->{evalue} , $hit->{function} ,
				$hit->{organism} , $hit->{source} , ($hit->{tax_id} || '' ) ), "\n" ;
				
				unless ($hit->{md5}){
					print STDERR Dumper $hit , \@block ;
				}
				
			}
			else{
				print STDERR "Not implemented yet!\n" ;
				exit;
			}
		
		}	
		
		
		my $stop = time ;
		# print STDERR "\t" , "Elapsed time:" , ($stop - $start) , "\n" if ($current_read);
		
		# reset for new read
		$current_read = $read ;
		@block = () ;
	}
	
	
	
	push @block , {
		read => $read , 
		md5 => $md5 , 
		function => $function , 
		organism => $organism , 
		tax_id => $tax_id ,
		source => $source    ,
		identity => $identity , 
		length => $length , 
		mismatch => $mismatch , 
		gaps => $gaps , 
		query_start => $q_start , 
		query_end => $q_end ,
		subject_start => $s_star , 
		subject_end => $s_end , 
		evalue => $evalue , 
		score => $score } ;
	
	# $md5hash->{$md5} = {
# 		read => $read ,
# 		md5 => $md5 ,
# 		function => $function ,
# 		organism => $organism ,
# 		tax_id => $tax_id ,
# 		identity => $identity ,
# 		length => $length ,
# 		mismatch => $mismatch ,
# 		gaps => $gaps ,
# 		query_start => $q_start ,
# 		query_end => $q_end ,
# 		subject_start => $s_star ,
# 		subject_end => $s_end ,
# 		evalue => $evalue ,
# 		score => $score
# 	} unless( exists $md5hash->{$md5} );
	
}