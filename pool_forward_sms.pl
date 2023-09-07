#!/usr/bin/perl

use LWP::UserAgent;

my $transactiontype = $ARGV[0] || die;
my $smsmsessagefile = $ARGV[1];
my $POOLDIR = "/run/smstools/";
# Change that endpoint to your own ingestor
our $POST_ENDPOINT = "https://example.com/manager/sim_cards/sms/receive";

# Examples
# -------------------------------------------------- RECEIVED
# From: 44xxxxxxxxxx
# From_TOA: 91 international, ISDN/telephone
# From_SMSC: 44yyyyyyyyyy
# Sent: 18-04-12 10:37:27
# Received: 18-04-12 09:37:42
# Subject: GSM1
# Modem: GSM1
# IMSI: 23nnnnnnnnnnnnn
# IMEI: 86mmmmmmmm
# Report: yes
# Alphabet: ISO
# Length: 19
#
# Test 2
# -------------------------------------------------- SENT
# To: xxxxxxxxxx
# Modem: GSM1
# Sent: 18-04-23 09:29:49
# Sending_time: 5
# IMSI: 23nnnnnnnnnnnnn
# IMEI: 86mmmmmmmm
#
# THIS IS ALSO A TEST
# --------------------------------------------------

my ( $FROM, $FROMTOA, $FROMSMSC, $RECEIVED, $SUBJECT, $REPORT, $ALPHABET, $LENGTH ) = ('')x8;	# RX
my ( $SENTTO, $SENDINGTIME ) = ('')x2;								# TX
my ( $SQL, $SENT, $MODEM, $IMSI, $IMEI, $actualmessage ) = ('')x6;				# Common

if ( $transactiontype =~  /RECEIVED/ )
	{
	open (SMS, "<$smsmsessagefile") || die "Can't open $smsmsessagefile\n";	
	binmode SMS;
	local $/;
	my $SMSDATA = <SMS>;
	close SMS;

	my $EndOfHeaders = 0;

	my @splitSMSDATA = split('\n', $SMSDATA);

	foreach my $line( @splitSMSDATA )
		{
		if    ( $line =~ /^From:\s(.*)$/ )	{ $FROM = $1; }
		elsif ( $line =~ /^From_TOA:\s(.*)$/ )	{ $FROMTOA = $1; }
		elsif ( $line =~ /^From_SMSC:\s(.*)$/ )	{ $FROMSMSC = $1; }
		elsif ( $line =~ /^Sent:\s(.*)$/ )	{ $SENT = $1; }
		elsif ( $line =~ /^Received:\s(.*)$/ )	{ $RECEIVED = $1; }
		elsif ( $line =~ /^Subject:\s(.*)$/ )	{ $SUBJECT = $1; }
		elsif ( $line =~ /^Modem:\s(.*)$/ )	{ $MODEM = $1; }
		elsif ( $line =~ /^IMSI:\s(.*)$/ )	{ $IMSI = $1; }
		elsif ( $line =~ /^IMEI:\s(.*)$/ )	{ $IMEI = $1; }
		elsif ( $line =~ /^Report:\s(.*)$/ )	{ $REPORT = $1; }
		elsif ( $line =~ /^Alphabet:\s(.*)$/ )	{ $ALPHABET = $1; }
		elsif ( $line =~ /^Length:\s(.*)$/ )	{ $LENGTH = $1; }
		elsif ( $line =~ /^To:\s(.*)$/ )	{ $SENTTO = $1; }
		elsif ( $line =~ /^Sending_time:\s(.*)$/ ){ $SENDINGTIME = $1; }
		elsif ( $line =~ /^$/ && !EndOfHeaders )  { $EndOfHeaders = 1; }
		}

		my $startcounter = 0;

		if ( $transactiontype =~  /RECEIVED/ )		{ $startcounter = 13; }
		elsif ( $transactiontype =~  /FAILED|SENT/ )	{ $startcounter = 7; }

		for ( my $ctr = $startcounter; $ctr < scalar @splitSMSDATA; ++$ctr )
			{	
			my $messagechunk	= $splitSMSDATA[$ctr];
			$actualmessage .= $messagechunk; 	
			}
			$actualmessage =~ s/[^[:print:]]+//g;
			print STDERR "Actual message is : $actualmessage\n";
			my $port = $MODEM;
			$port =~ s/Port//;
			chomp($port);
			open($fh,"<",$POOLDIR.$port."_current");
			my $current_slot = <$fh>;
			chomp($current_slot);
			my $location = $port . "x".$current_slot;

			my $ua      = LWP::UserAgent->new(); 
			my $response = $ua->post( $POST_ENDPOINT, [ 'from' => $FROM, 'contents' => $actualmessage,'location' =>  $location] ); 
			my $content = $response->decoded_content; 
			print STDERR "Response is:".$content."\n";
			if($content =~ /OK/){
				unlink $smsmsessagefile;
				print STDERR "Message forwarded.File deleted\n";
			}

		}
	else
		{ die "TYPE IS NOT RECEIVED/SENT/FAILED\n"; }


exit 0;