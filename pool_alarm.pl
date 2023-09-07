#!/usr/bin/perl

use LWP::UserAgent;

#my $transactiontype = $ARGV[0] || die;
my $smsmsessagefile = $ARGV[1];
my $POOLDIR = "/run/smstools/";

# Change that endpoint to your own ingestor
our $POST_ENDPOINT = "https://example.com/manager/sim_cards/status";


#open (LOGFILE, ">>/home/socks/smsd_alarms.log");

#foreach(@ARGV){
#	print LOGFILE "$_\n";
#}

# print  LOGFILE $ARGV[5]; 

if($ARGV[5] =~ /Done\: alarmhandler/){
	$ARGV[4] =~ m/Port(\d+)/;
	$modem = $1;
	open(SLOT,"<".$POOLDIR.$modem."_current");
	$slot = <SLOT>;
	chomp($slot);
	#	print LOGFILE "\nModem $1 x $slot is receiving messages\n";
	my $ua      = LWP::UserAgent->new(); 
	my $response = $ua->post( $POST_ENDPOINT, [ 'location' =>  $modem.'x'.$slot] ); 
	my $content = $response->decoded_content; 
	print STDERR "Response is:".$content."\n";
}


close LOGFILE;
