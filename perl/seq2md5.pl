use strict;
use warnings;
use Data::Dumper;
use JSON;    # imports encode_json, decode_json, to_json and from_json.
use LWP::UserAgent;
use HTTP::Request::Common;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Getopt::Long;
use File::Copy;

my $md5 = Digest::MD5->new;

my $id    = '';
my $url   = '';
my $source = '' ; # other UNITE , ...
my $fasta_file  = '';
my $tab_file  = '';
my @files = ();
my %query;

GetOptions(
    'fasta=s'  => \$fasta_file,
    'tab=s'    => \$tab_file,
	'source=s' => \$source,
  );
  
  # output md5, id, function, organism, source , sequence


if ($fasta_file){
	
	$/ = "\n>" ;
	open(FASTA , $fasta_file) ;
	
	while(my $record = <FASTA>){
		
		chomp $record ;
		my ($header , @seqs) = split "\n" , $record ;
		
		
		
		
		my ($id , $org , $func , $aliases , @remainder) = parseHeader($header , $source) ;
		
		
		my $seq      = uc(join "" , @seqs) ;
		my $checksum = seq2hexdigest($seq);
		 	
		print STDERR $header unless($id) ;		
		print join "\t" ,  $checksum , $id , $func , $org , ($source || 'undefined') , (join ";" , @$aliases) , $seq , "\n" ;
		
	}
	
	
}


sub seq2hexdigest{
	my ($seq) = @_ ;
	
	$md5->reset ;
	$md5->add( uc($seq) );
	my $checksum = $md5->hexdigest;
	
	return $checksum ;
}


sub parseHeader{
	my ($header , $source) = @_ ;
	
	$source = '' unless($source) ;
	
	my ($id , $org , $func , @aliases , @remainder) ; 
	
	if ($source eq 'UNITE'){
		my $alias = undef ;
		my $taxa  = { d => 'Eukaryota' };
		
		$func = 'ITS' ;
		($id , $org , $alias , @remainder) = $header =~/>{0,1}([^\|]+)\|([^\|]+)\|?([^\s]*)(.*)/ ;
		
		my (@levels) = split ";" , $org ;
		foreach my $l (@levels) {
			my ($t , $name) = $l =~ /(\w)_+(.+)/ ;
			$taxa->{$t} = $name ;
		}
		
		# added d__Eukaryota
		#k__Fungi;p__Basidiomycota;c__Agaricomycetes;o__Thelephorales;f__Thelephoraceae;g__Thelephora;s__Thelephora albomarginata
		my @all ;
		foreach my $l ('d' , 'k' , 'p' , 'c' , 'o' ,'f' ,'g' ,'s'){
			push  @all , $taxa->{$l}  ;
		}
		print STDERR join "\t" , $taxa->{s} , @all , "\n" ;
		$org = $taxa->{s} ;
		
		push @aliases , $alias  if ($alias) ;
	}
	else{
		($id , @remainder) = $header =~/>{0,1}([^\s]+)\s*(.*)/ ;
	}
	
	return ($id , $org , $func , \@aliases , \@remainder) ;
}


