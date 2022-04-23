#! /usr/bin/perl
#
# Created by Valynkin P.S. 31.03.2021
#
use strict;
#use Data::Dumper;
use Sys::Syslog;
use JSON;
use File::Basename;

use subs qw/say/;
use subs qw/quit/;
use subs qw/err/;
$SIG{INT} = sub { quit "Caught a sigint $!" };
my $myname = basename(__FILE__);
my $mydir  = dirname(__FILE__);
$mydir = `pwd` if ( $mydir eq '.' );
chomp $mydir;

# ====== Preferences and constants ====== #
my $CONFIG_FILE="$mydir/pve-backup.conf";
my $LOCK_FILE='/tmp/'.$myname.'.lock';
my $PVESH='/usr/bin/pvesh';
my $LOG_FACILITY='local1';
my $debug = 0; # debug levels: 0, 1
# ========= End of preferences ========== #

# ========= Global variables ============ #
our @EXCLUDE=();
our $STORAGE;
our $MAX_FILES;
our $OPTIONS;
my %VMLIST=();
my $OUT;
# ========= End of gobal variables ====== #

# ========= Main program ================ #

# Open log
openlog("$myname", "nofatal,perror,pid", $LOG_FACILITY);
say "Program started";
&lock_set;

# Load exclude array from file
err "Unable to open $CONFIG_FILE" if ( !-e $CONFIG_FILE );
do $CONFIG_FILE || err "Unable to load $CONFIG_FILE";

# Load list of VM's from proxmox
my $json=`$PVESH get /cluster/resources -type vm  --output-format json` || err "Unable to get VM resources list from proxmox: $!";

my $data_structure = decode_json($json);
my @pve_resources=@{$data_structure};

# Populate hash VMLIST with data;
foreach my $i ( @pve_resources ) {
  next if ( %{$i}{'status'} ne 'running');
  $VMLIST{ %{$i}{'vmid'} }=%{$i}{'node'};
}

# Backup VMS
foreach my $vm ( sort ( keys %VMLIST ) ) {
  if ( $vm ~~ @EXCLUDE ) {
    say "$vm in exclude list- skipping";
    next;
  }
  say "Backup: $vm";
  $OUT = `$PVESH  create /nodes/$VMLIST{$vm}/vzdump -vmid=$vm -storage=$STORAGE -maxfiles=$MAX_FILES $OPTIONS`; say "ERROR: Unable to backup $vm:  $!" if $?;
}

quit "All DONE!";
# ========= End of Main program ========= #

# ========= Subroutines ================= #
sub say {
    my $msg = shift;
    syslog('info', "$msg");
#    print "$msg \n" if $debug;
}

sub err {
    my $msg = shift;
    syslog('err', 'ERROR: '."$msg");
#    print 'ERROR: '."$msg \n" if $debug;
    closelog;
    &lock_unset;
    die;
}

sub quit {
    my $msg = shift;
    syslog('err', "$msg");
#    print "$msg \n" if $debug;
    closelog;
    &lock_unset;
    exit;
}

sub lock_set {
  err "Lock file $LOCK_FILE found, exit now" if ( -e $LOCK_FILE);
  `date > $LOCK_FILE`;
}

sub lock_unset {
  `rm -f $LOCK_FILE` if ( -e $LOCK_FILE);
}
# ========= End of Subroutines ========== #
