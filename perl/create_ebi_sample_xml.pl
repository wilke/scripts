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

GetOptions(
     'metagenome_id=s' => \$metagenome_id ,
     'url=s' => \$url ,
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


# get ncbi scientific name and tax id
my ($ncbiScientificName,$ncbiTaxId) = get_ncbiScientificNameTaxID() ;

# Fill template now:

my $sample_alias = $data->{metadata}->{sample}->{id};
my $sample_name  = $data->{name};
my $center_name  = $data->{metadata}->{project}->{PI_organization};

my $sample_xml = <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<SAMPLE_SET xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:noNamespaceSchemaLocation="ftp://ftp.sra.ebi.ac.uk/meta/xsd/sra_1_5/SRA.sample.xsd">
     <SAMPLE alias="$sample_alias"
center_name="$center_name">
         <TITLE>$sample_name . " " . $ncbiScientificName</TITLE>
         <SAMPLE_NAME>
         <!--
http://www.ebi.ac.uk/ena/data/view/Taxon:410656&display=xml -->
         <!-- Map \$metagenome{metadata}{sample}{data}{env_package} to
\$ncbiTaxId and \$ncbiScientificName --->
         <!-- Else map \$metagenome{metadata}{sample}{data}{biome} to
\$ncbiTaxId and \$ncbiScientificName --->
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


print $sample_xml;

# function for ncbi tax name id lookup
sub get_ncbiScientificNameTaxID{
     my ($term) = @_ ;
     return ('test' , 'forget') ;
}