####################################################
# Query NCBI, retrieve sequences for accession IDs
####################################################

use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP::UserAgent ;
use HTTP::Request::Common;
use DB_File ; # for local Berkeley DB

use Getopt::Long;


my $file 		= undef ;
my $verbose 	= 0 ;
my $source 		= undef ;
my $format  	= undef ;
my $column      = 1 ; # default column, in the code is $column - 1
my $base_url 	= "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi" ;
my $dbfile      = undef ;
my $batch_size  = 100 ;

GetOptions (
	'file=s' 	=> \$file,
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

my $md5 = Digest::MD5->new;

# LWP
my $ua = LWP::UserAgent->new();
$ua->agent('Sequence4Accession 0.1'); 
#$ua->timeout(1000);
$ua->env_proxy;


open(FILE , $file) or die "Can't open file $file!\n" ;

while(my $line = <FILE>){
	
	chomp $line ;
	my @fields = split "\t" , $line ;
	
	my $response = $ua->get( $base_url."?db=nuccore&rettype=fasta&retmode=text&id=".$fields[$column-1] );
	
	
	
	if ($response->is_success) {
	    #print $response->decoded_content;  # or whatever
	
		# print $response->decoded_content ;
		
		my ($header , @seqs) = split "\n" , $response->decoded_content ;
		
		my ($ids , $func , $org) = $header =~/^>([^\s]+)\s(.*)\s\[(.*)\]/ ;
		
		my $seq      = uc(join "" , @seqs) ;
		my $checksum = seq2hexdigest($seq);
		
		print join "\t" , $checksum , $fields[$column-1] , ($func || '') ,($org || '') , 'ARDB_annotation' , $seq ;
		print "\n" ;
		print join "\t" , $checksum , $fields[$column-1] , $fields[1] , '' , 'ARDB' ;
		print "\n" ;
		
		# my $tmp = $json->decode( $response->decoded_content ) ;
		# $md52annotation = $tmp->{data} ;
		# print STDERR Dumper $tmp ;
	}
	else {
	    die $response->status_line;
	} 
}



sub seq2hexdigest{
	my ($seq) = @_ ;
	
	$md5->reset ;
	$md5->add( uc($seq) );
	my $checksum = $md5->hexdigest;
	
	return $checksum ;
}


