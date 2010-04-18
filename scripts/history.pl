#!/usr/bin/perl

# A history script with enable and disable options
#
# This manages a history file. Writing to history can be enabled and disbaled.

# This script sets a variable to be used in the status bar:
# hist_status - <span foreground="#FF0000/#00FF00">H</span>
# The H is in red color when disabled, green when enabled
# To see these variables add \@hist_status to the
# status_format viariable in the config file.
#
# To install, place this script at your scripts_dir and add the following lines to your config file:
# @on_event   LOAD_COMMIT    spawn @scripts_dir/history.pl 

# @cbind sbh = spawn @scripts_dir/history.pl disable
# @cbind suh = spawn @scripts_dir/history.pl enable

use strict;
use warnings;

my $histfile = "$ENV{HOME}/.local/share/uzbl/history";
exit unless -f $histfile;
my $lockfile = "$ENV{HOME}/.local/share/uzbl/histlock";

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

$action = "" unless defined $action;
my $enable_history = 1;
$enable_history = 0 if -f $lockfile;

if($action eq ""){
    my $status_cmd = "set hist_status = <span foreground=\\\"#00FF00\\\">H</span>\n";
    $status_cmd = "set hist_status = <span foreground=\\\"#FF0000\\\">H</span>\n" if $enable_history == 0;
    open(FIFO,">>$fifo");
    print FIFO $status_cmd;
    close(FIFO);

    exit unless $url =~ m/(http|https|file):\/\//;
    my $time = `date +'%Y-%m-%d %H:%M:%S'`;
    chomp $time;
    `echo "$time $url $title" >> $histfile` if $enable_history == 1;
} elsif($action eq "enable"){
    unlink $lockfile;
} elsif($action eq "disable"){
    open(LOCKFILE,">$lockfile");
    print LOCKFILE "1\n";
    close(LOCKFILE);
}
