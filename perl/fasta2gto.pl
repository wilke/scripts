use strict ;
use warnings;
use Data::Dumper;
use JSON; # imports encode_json, decode_json, to_json and from_json.


use Getopt::Long;


my $fasta 		      = undef ;
my $verbose 	      = 0 ;
my $nr_records        = 5000 ;
my $id                = 'ChunkedMetagenome';
my $path_and_filename = "./tmp" ;

my $json              = new JSON ; 

my $gto = {
   "domain" 		=> "Bacteria",
   "contigs" 		=> [],
   "features" 		=> [],
   "close_genomes" 	=> [],
   "genetic_code" 	=> "11",
   "id" 			=> "$id",
   "analysis_events" => [
      	{
         	"parameters" => [
            	"genetic_code=11",
            	"min_training_len=2000"
         	   ],
         	  "hostname" 		=> "redwood",
			  "tool_name" 		=> "glimmer3",
			  "id" 				=> "94a9a974-ffbd-4b82-b23e-6c61f49cd0e2",
			  "execution_time" 	=> "1429300121.55494"
		  } ],
};
   
   

GetOptions (
	'verbose+'   => \$verbose,
	'fasta=s'	 => \$fasta,
	'records=i'	 => \$nr_records,
	'filename=s' => \$path_and_filename ,
);
	

$/ = "\n>" ;
open(FASTA , $fasta) or die "Can't open file $fasta for reading!\n" ;

my @records ;
my $counter = 1;
while(my $record = <FASTA>){
	print $record ;
	
	# remove line end character, here \n>
	
	chomp $record ;
	
	push @records , $record ;
	
	if (scalar @records >= $nr_records){
		create_gto(\@records) ;
		dump_gto($path_and_filename , $counter) ;
		$counter++
	}
}

# create gto for last record set
create_gto(\@records) if (@records);
dump_gto($path_and_filename , $counter) ;

close(FASTA);	


sub create_gto{
	my ($records) = @_ ;

	foreach my $record (@$records){
		my($header,$seq) = split "\n" , $record ;
		my ($id) = $header =~/>*([^\s]+)/;
		
		
		
		my $feature = { 
			"protein_translation" => $seq ,
			"id" => $id ,
			"type" => "CDS",
			"location" => [],
		};
		
		push @{$gto->{features}} , $feature	;		
	}	
}

sub dump_gto{
	my ($filename , $counter) = @_;
	
	open(GTO , ">$filename.$counter.gto") or die "Can't open $filename.$counter.gto for writing!\n" ;
	print GTO $json->encode($gto) ;
	close(GTO);
	
	$gto->{features} = [] ;
}



