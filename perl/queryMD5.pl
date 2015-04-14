use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.
use LWP::UserAgent ;
use HTTP::Request::Common;
 use Digest::MD5 qw(md5 md5_hex md5_base64);
 
use Getopt::Long;
use File::Copy;

my $md5 = Digest::MD5->new;

my $id       = '';
my $url      = '';
my $file    = '';
my @files     = ();
my %query;

GetOptions (
			'fasta=s' 	=> \$file,
			);
			
while(<>){
	        chomp;
	        print "\n$_\t" if /^>/;
	        print $_ unless /^>/;
	}

while (my $line = <FILE>){	
	
	chomp $line;
	my ($header, $seq) = split "\t" , $line ;
						
							
	# do something with sequence
	
	$md5->add($seq);
	my $digest = $md5->digest;
	
	print join "\t" , $header , $digest , "\n" ;
	
	}