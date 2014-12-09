#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper ;
use LWP::UserAgent;
use JSON;
use Getopt::Long;

# Example:
# http://api.metagenomics.anl.gov//metagenome/mgm4447943.3?verbosity=full

# metagenome id
my $metagenome_id = undef ;

# mgrast base api url
my $url = "http://api.metagenomics.anl.gov/" ;

# resource name
my $resource = "metagenome" ;

# api parameter
my $options = "?verbosity=metadata";

# submit to ena , default is false
my $submit = 0 ;

# schema/object type
my $type = "Sample" ;

# submission id
my $submission_id = undef ;

# ENA URL
my $auth = "ERA%20era-drop-115%20mFaAsrkPbdOq/qbm/8vRTzB5enk%3D" ;
my $ena_url = "https://www-test.ebi.ac.uk/ena/submit/drop-box/submit/?auth=$auth";

GetOptions(
     'metagenome_id=s' => \$metagenome_id ,
     'url=s'  => \$url ,
	 'submit' => \$submit,
	 'submission_id=s' => \$submission_id,
);


# initialise user agent
my $ua = LWP::UserAgent->new;
$ua->agent('EBI Client 0.1');

# retrieve data
my $response = $ua->get( join "/" , $url, $resource , $metagenome_id ,
$options);

unless($response->is_success){ 
     print STDERR "Error retrieving data for $metagenome_id.\n";
     # add http error message
     exit;
}

my $json = new JSON;
my $data = undef;

# error handling if not json
eval{
     $data = $json->decode($response->content)
};

if($@){
     print STDERR "Error: $@\n";
     exit;
}

# created xml
my $xml = undef ;

# center name is used in sample and submisison
my $center_name  = $data->{metadata}->{project}->{PI_organization} || "unknown" ;

if($type eq "Sample"){
	$xml = get_sample_xml($data) ;
}



if($submit){
	submit($type,$xml,$submission_id,$center_name)
}
else{
	print $xml
}


sub get_sample_xml{
	my ($data) = @_;

	# get ncbi scientific name and tax id
	my ($ncbiScientificName,$ncbiTaxId) = get_ncbiScientificNameTaxID() ;

	# Fill template now:

	my $sample_alias = $data->{metadata}->{sample}->{id};
	my $sample_name  = $data->{name};
	my $center_name  = $data->{metadata}->{project}->{PI_organization} || "unknown" ;

	my $sample_xml = <<"EOF";
	<?xml version="1.0" encoding="UTF-8"?>
	<SAMPLE_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:noNamespaceSchemaLocation="ftp://ftp.sra.ebi.ac.uk/meta/xsd/sra_1_5/SRA.sample.xsd">
	     <SAMPLE alias="$sample_alias" 
		 center_name="$center_name">
	         <TITLE>$sample_name . " " . $ncbiScientificName</TITLE>
	         <SAMPLE_NAME>
	             <TAXON_ID>$ncbiTaxId</TAXON_ID>
				 <SCIENTIFIC_NAME>$ncbiScientificName</SCIENTIFIC_NAME>
	         </SAMPLE_NAME>
	         <DESCRIPTION>$sample_name . " " . $ncbiScientificName</DESCRIPTION>
	         <SAMPLE_ATTRIBUTES>
EOF
	
	             foreach my $key ( keys
	%{$data->{metadata}->{sample}->{data} } )
	             {
	             my $value = $data->{metadata}->{sample}->{data}->{$key} ;
	             $sample_xml .= <<"EOF";
	             <SAMPLE_ATTRIBUTE>
	                 <TAG>$key</TAG>
	                 <VALUE>$value</VALUE>
	             </SAMPLE_ATTRIBUTE>
EOF
	             }

	             foreach my $key ( keys
	%{$data->{metadata}->{env_package}->{data} } )
	             {
	                 my $value =
	$data->{metadata}->{env_package}->{data}->{$key} ;
	                 $sample_xml .= <<"EOF";
	             <SAMPLE_ATTRIBUTE>
	                 <TAG>$key</TAG>
	                 <VALUE>$value</VALUE>
	             </SAMPLE_ATTRIBUTE>
EOF
	             }

	     $sample_xml .= <<"EOF";
	         </SAMPLE_ATTRIBUTES>
	     </SAMPLE>
	</SAMPLE_SET>
EOF

	return $sample_xml ;
}

# function for ncbi tax name id lookup
sub get_ncbiScientificNameTaxID{
     my ($term) = @_ ;
     return ('test' , 'forget') ;
}


sub submit{
	
	my ($type,$xml,$submission_id,$center_name) = @_ ;
	
	unless($submission_id){
		print STDERR "No submission id\n";
		exit;
	}

	my $schema = lc($type) ;

	my $submission = <<"EOF" ;
	
	<?xml version="1.0" encoding="UTF-8"?>
	<SUBMISSION_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:noNamespaceSchemaLocation="ftp://ftp.sra.ebi.ac.uk/meta/xsd/sra_1_5/SRA.submission.xsd">
	<SUBMISSION alias="$submission_id"
	  center_name="$center_name">
	         <ACTIONS>
	             <ACTION>
	                 <ADD source="sample.xml" schema="$schema"/>
	             </ACTION>
	         </ACTIONS>
	     </SUBMISSION>
	</SUBMISSION_SET>
EOF

	# dump $type xml 
	open(FILE , ">$schema.xml");
	print FILE $xml ;
	close(FILE);

	# dump submission xml
	open(FILE , ">submission.xml");
	print FILE  $submission ;
	close FILE;

	my $stype = uc($type);
	print "curl -F \"SUBMISSION=\@submission.xml\" -F \"$stype=\@$schema.xml\" \"$ena_url\"\n";
	my $receipt = `curl -F "SUBMISSION=\@submission.xml" -F "$stype=\@$schema.xml "$ena_url"` ;

	print $submission ;
	print $receipt , "\n";

	my $log = undef;

	return $log ;
}