#!/usr/bin/perl
use strict;
use warnings;
use Device::SerialPort qw( :PARAM :STAT 0.07 );

$| = 1;

my $POOLDIR = "/run/smstools/";

our $PORTS = 8;
our $SLOTS = 16;
our %STATS;
our $DEBUG = 2;

for(my $i=1;$i<=$PORTS;$i++){
  $STATS{$i} = 1;
}

our $SLEEP_INTERVAL = 200;


my $ob = &initPool("init");


while( 1 ) {
  foreach my $current_port(keys %STATS){
    my $current_slot = $STATS{$current_port};
    if(-s $POOLDIR.$current_port."_next"){
        open(my $next_fh,"<",$POOLDIR.$current_port."_next");
        my $next_slot = <$next_fh>;
        chomp($next_slot);
        if( ($next_slot/1 > 0) && ($next_slot/1 <= $SLOTS ) ){
          print STDERR "Setting next slot for PORT $current_port TO $next_slot from file\n" if $DEBUG;
          $current_slot = $next_slot;
          $STATS{$current_port} = $current_slot;  
          unlink($POOLDIR.$current_port."_next");
        }
      }
   
     print "Switching PORT $current_port to SLOT : $current_slot";
    unless($ob){
      $ob = &initPool();
    }
    if( ! sendCommand($ob,sprintf("AT+SWIT%02d-%04d",$current_port,$current_slot),"SWITCH OK") ){
      print STDERR "Switch unsuccesful\n" if $DEBUG;
    }
    else{
      &syncPort($current_port,$current_slot);
      print STDERR "Increasing SLOT number\n" if $DEBUG;
      
      if($STATS{$current_port} >= $SLOTS){
        $STATS{$current_port} = 1;
      }
      else{
        $STATS{$current_port}++;
      }
    }
  }
  
  sleep($SLEEP_INTERVAL);
}

sub syncStats{
  my %memstats = %{$_[0]};
  foreach my $current_port(keys %memstats){
    open(my $file,">",$POOLDIR.$current_port."_current");
    print $file $memstats{$current_port};
    close($file);
  }
}
sub syncPort{
    my ($current_port,$slot) = @_;
    open(my $file,">",$POOLDIR.$current_port."_current");
    print $file $slot;
    close($file);
}
sub sendCommand{
  my $STALL_DEFAULT = 10;
  my $timeout = $STALL_DEFAULT;

  my ($ob,$command,$expect) = @_;
  print STDERR "\nSending command : $command and expecting :$expect\n" if $DEBUG;
  my $chars=0;
  my $buffer="";
CMDLOOP:
  while ($timeout>0) {
  	
  	chomp($command);
  	my $output_string = "$command\r";
    my $count_out = $ob->write($output_string);
  	warn "write failed\n"         unless ($count_out);
  	warn "write incomplete\n"     if ( $count_out != length($output_string) );
     my ($count,$saw)=$ob->read(255); # will read _up to_ 255 chars
     if ($count > 0) {
             $chars+=$count;
             $buffer.=$saw;
		           print "Output is : $buffer";
             # Check here to see if what we want is in the $buffer
             # say "last" if we find it
             if($buffer =~ m/\Q$expect/){
               print "Command successful\n";
               last CMDLOOP;
             }
     }
     else {
             $timeout--;
     }
     $ob->purge_all;
  }
   
  if ($timeout==0) {
         print STDERR "Waited $STALL_DEFAULT seconds and never saw what I wanted\n";
         return 0;
  }
  return 1;
}


sub initPool{
  my $port = '/dev/ttyUSB0';
  my $conf = '~/.conf';
  my $ob = Device::SerialPort->new($port, 1)
      || return undef;
      
  
  my $arb  = $ob->can_arbitrary_baud;
  my $data = $ob->databits(8);
  my $baud = $ob->baudrate(115200);
  my $parity = $ob->parity("none");
  my $hshake = $ob->handshake("rts");
  my $stop = $ob->can_stopbits();
  my $rs = $ob->is_rs232; 
  my $total = $ob->can_total_timeout;

  $ob->debug(1);
  $ob->stopbits(1);
  $ob->buffers( 4096, 4096 );
  $ob->can_baud;
  $ob->can_databits;
  $ob->can_dtrdsr;
  $ob->can_handshake;
  $ob->can_parity_check;
  $ob->can_parity_config;
  $ob->can_parity_enable;
  $ob->can_rtscts;
  $ob->can_xonxoff;
  $ob->can_xon_char;
  $ob->can_spec_char;
  $ob->can_interval_timeout;
  $ob->can_ioctl;
  $ob->can_status;
  $ob->can_write_done;
  $ob->can_modemlines;
  $ob->can_wait_modemlines;
  $ob->can_intr_count;
  $ob->write_settings;

  print 
  "A = $arb\n",
  "B = $baud\n",
  "D = $data\n", 
  "S = $stop\n",
  "P = $parity\n",
  "H = $hshake\n",
  "R = $rs\n",
  "T = $total";

  $ob->read_char_time(0);     # don't wait for each character
  $ob->read_const_time(1500); # 1 second per unfulfilled "read" call
  if($_[0] eq "init"){
    if(sendCommand($ob,"AT+CWSIM","CWSIM OK")){
      return $ob;  
    }
    else{
      return 0;
    }
  }
  else{
    return $ob;  
  }
  
  
}
