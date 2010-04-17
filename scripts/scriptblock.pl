#!/usr/bin/perl
# Per site script/plugin blocker
#
# This is a perl port of the shell-script by Pail Tomak
# The shell script didn't work for me so I ported it to perl
# Error message was:
# scriptblock.sh: 91: Syntax error: "elif" unexpected (expecting "then")
#
# I added some small enhancements
#
# To use this script add:
# @on_event LOAD_COMMIT spawn @scripts_dir/scriptblock.sh
# in your config file.
# When called without any parameter script will set per-domain setting or
# default ones, if there aren't any for current domain
#
# By default it sets the disable_scripts variable to 0 (scripts enabled) and
# disable_plugins to 1 (plugis are disabled). This can be overriten by setting
# this variables in config file:
# set disable_plugins = 0
# set disable_scripts = 1
#
# To manage domains there are four actions:
# unblock_plugins/unblock_scripts - to unblock plugins/scripts for current
# domain
# block_plugins/block_scripts - to block plugins/scripts for current domain
# For example:
# @cbind sus = spawn @scripts_dir/scriptblock.sh unblock_scripts
# @cbind sup = spawn @scripts_dir/scriptblock.sh unblock_plugins
# @cbind sbs = spawn @scripts_dir/scriptblock.sh block_scripts
# @cbind sbp = spawn @scripts_dir/scriptblock.sh block_plugins
#
# This script also sets two variables to be used in the status bar:
# scripts_status - <span foreground="#FF0000/#00FF00">scripts</span>
# plugins_status - <span foreground="#FF0000/#00FF00">plugins</span>
# scripts/plugins text is in red color when disabled, green when enabled
# To see these variables add \@scripts_status and/or \@plugins_status to the
# status_format viariable in the config file.
#
# Writen by Paul Tomak <paul.tomak@gmail.com>
#

use strict;
use warnings;

my $keydir=$ENV{HOME}."/.local/share/uzbl";

#exit if -d `dirname $keydir`;
#[ -d $keydir ] || mkdir $keydir || exit 1
mkdir $keydir unless -d $keydir;

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

$action = "" unless defined $action;

my $domain = $url;
$domain =~ s/(http|https):\/\/([^\/]+)\/.*/$2/;

#print "keydir = $keydir, domain = $domain, action = $action\n";



my $scripts_state=`sed -n "s/$domain \\([01]\\) [01]/\\1/p" $keydir/scriptblock.txt`;
$scripts_state=`sed -n 's/set[[:blank:]]\\+disable_scripts[[:blank:]]\\+=[[:blank:]]\\+\\([01]\\)/\\1/p' $config` if $scripts_state eq "";

my $plugins_state=`sed -n "s/$domain [01] \\([01]\\)/\\1/p" $keydir/scriptblock.txt`;
$plugins_state=`sed -n 's/set[[:blank:]]\\+disable_plugins[[:blank:]]\\+=[[:blank:]]\\+\\([01]\\)/\\1/p' $config` if $plugins_state eq "";



#print "scripts_state = $scripts_state\n";
#print "plugins_state = $plugins_state\n";

if($action eq ""){
    `echo "set disable_plugins = $plugins_state" >> $fifo`;
    `echo "set disable_scripts = $scripts_state" >> $fifo`;
    if($scripts_state == 1){
        `echo "set scripts_status = <span foreground=\\\"#FF0000\\\">S</span>" >> $fifo`;
#        print "set scripts_status = <span foreground=\\\"#FF0000\\\">S</span> >> $fifo\n";
    } else {
        `echo "set scripts_status = <span foreground=\\\"#00FF00\\\">S</span>" >> $fifo`;
#        print "set scripts_status = <span foreground=\\\"#00FF00\\\">S</span> >> $fifo\n";
    }
    if($plugins_state == 1){
        `echo "set plugins_status = <span foreground=\\\"#FF0000\\\">P</span>" >> $fifo`;
#        print "set plugins_status = <span foreground=\\\"#FF0000\\\">P</span> >> $fifo\n";
   } else {
        `echo "set plugins_status = <span foreground=\\\"#00FF00\\\">P</span>" >> $fifo`;
#        print "set plugins_status = <span foreground=\\\"#00FF00\\\">P</span> >> $fifo\n";
    }
} elsif($action eq 'unblock_scripts'){
    if(`grep $domain $keydir/scriptblock.txt`."x" eq "x"){
        chomp $plugins_state;
        `echo $domain 0 $plugins_state >> $keydir/scriptblock.txt`;
#        print "$domain 0 $plugins_state >> $keydir/scriptblock.txt\n";
    } else {
        `sed "s/\\($domain\\) [01] \\([01]\\)/\\1 0 \\2/" -i $keydir/scriptblock.txt`;
        #print "sed \"s/\($domain\) [01] \([01]\)/\1 0 \2/\" -i $keydir/scriptblock.txt\n";
    }
} elsif($action eq 'unblock_plugins'){
    if(`grep $domain  $keydir/scriptblock.txt`."x" eq "x"){
        chomp $scripts_state;
        `echo $domain $scripts_state 0 >> $keydir/scriptblock.txt`;
        #print " $domain 0 0 >> $keydir/scriptblock.txt\n";
    } else {
        `sed "s/\\($domain\\) \\([01]\\) [01]/\\1 \\2 0/" -i $keydir/scriptblock.txt`;
        #print "sed \"s/\\($domain\\) \\([01]\\) [01]/\\1 \\2 0/\" -i $keydir/scriptblock.txt\n";
    }
} elsif($action eq 'block_scripts'){
    if(`grep $domain  $keydir/scriptblock.txt`."x" eq "x"){
        chomp $plugins_state;
        `echo $domain 1 $plugins_state >> $keydir/scriptblock.txt`;
#        print " $domain 1 $plugins_state >> $keydir/scriptblock.txt\n";
    } else {
        `sed "s/\\($domain\\) [01] \\([01]\\)/\\1 1 \\2/" -i $keydir/scriptblock.txt`;
        #print "sed \"s/\\($domain\\) [01] \\([01]\\)/\\1 1 \\2/\" -i $keydir/scriptblock.txt\n";
    }
} elsif($action eq 'block_plugins'){
    if(`grep $domain  $keydir/scriptblock.txt`."x" eq "x"){
        chomp $scripts_state;
        `echo $domain $scripts_state 1 >> $keydir/scriptblock.txt`;
#        print " $domain $scripts_state 1 >> $keydir/scriptblock.txt\n";
    } else {
        `sed "s/\\($domain\\) \\([01]\\) [01]/\\1 \\2 1/" -i $keydir/scriptblock.txt`;
        print "sed \"s/\($domain\) \([01]\) [01]/\1 \2 1/\" -i $keydir/scriptblock.txt\n";
    }
}
