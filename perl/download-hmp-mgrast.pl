use strict;
use warnings;
no warnings('once');

use JSON;
use Config::Simple;
use Getopt::Long;
use LWP::UserAgent;
use MIME::Base64;
use Data::Dumper;



my $ua 		= LWP::UserAgent->new('HMP Download');
my $json 	= new JSON ;

my $base 	= 'http://api.metagenomics.anl.gov';
my $project = "mgp385";
my $verbose = 1;
my $logfile = "download.log";


open(LOG , ">$logfile") or die "Can't open $logfile for writing!\n";

print "Retrieving project from ".$base."/project/".$project."?verbosity=full\n" if ($verbose);

# Project URL
my $get = $ua->get($base."/project/".$project."?verbosity=full");

# check response status
unless ( $get->is_success ) {
	print STDERR join "\t", "ERROR:", $get->code, $get->status_line;
    exit 1;
}


# decode response
my $res 	= $json->decode( $get->content );
my $mglist 	= $res->{metagenomes} ;

# print STDERR $mglist, "\n";

# print Dumper $res ;

print "Searching for upload file\n" if ($verbose) ;

foreach my $tuple ( @$mglist ) {
	
	# url for all genome features	
	my $mg = $tuple->[0] ;
				
	print "Checking download url ". $base."/download/$mg\n";
	 			
	my $get = $ua->get($base."/download/$mg");
	
	# check response status
	unless ( $get->is_success ) {
		print STDERR join "\t", "ERROR:", $get->code, $get->status_line;
		exit 1;
	}
		
	my $res = $json->decode( $get->content );
		
	my $download = undef ;
	my $dstage   = undef ;
		
	foreach my $stage ( @{$res->{data} } ) {
			
		if ($stage->{stage_name} eq "upload"){
			$download = $stage->{url}; # use shock curl http://shock.metagenomics.anl.gov/node/caab6ef9-8087-4337-a217-54f8e9e40e7a
			$dstage   = $stage;	
			
			print join "\t" , $dstage->{stage_name} , $dstage->{file_name} , $dstage->{file_format} , $dstage->{url} , "\n"  if(defined $dstage);
		}	
		
	}
	 	
	if(defined $dstage){
		
		if( $dstage->{file_format} eq "fastq" ){
			# fastq	
			
			# download fasta via Shock with fastq to fasta converter turned on
			my $call = "curl 'http://shock.metagenomics.anl.gov/node/" . $dstage->{node_id}  . "&filter=fq2fa' >" . $dstage->{file_name} ;
			
			# download through mg-rast api
			#my $call = "curl $download > " . $dstage->{file_name} ;
			
			my $error = system $call ;
		}
		elsif( $dstage->{file_format} eq "fasta"){
			# fasta
			
			# download dasta via Shock
			my $call = "curl 'http://shock.metagenomics.anl.gov/node/" . $dstage->{node_id}  . "&filter=fq2fa' >" . $dstage->{file_name}  ;
			# download through mg-rast api
			# my $call = "curl $download > " . $dstage->{file_name} ;
			my $error = system $call ;
		}
		else{
			# PROBLEM
			print STDERR "Not a valid sequence type for $download\n" ;
		}
		
		print LOG join "\t" , $dstage->{node_id} , $dstage->{file_name} , $dstage->{"file_md5"} ;
		print LOG "\n" ;	
		
	}
	else{
		print STDERR "No upload stage for $mg\n" ;
	}	
		
}

close(LOG);