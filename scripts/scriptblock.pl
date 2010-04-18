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

# Set this variable to 1 to use the files as whitelists (then set disable_scripts and disable_plugins to 1 in config file. Set $whitelist to 0 to use the files as blacklists (then set disable_scripts and disable_plugins to 0 in the config file).

my $whitelist = 1;

my $keydir=$ENV{HOME}."/.local/share/uzbl";

exit unless -d $keydir;

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

$action = "" unless defined $action;

my $domain = $url;
$domain =~ s/(http|https):\/\/([^\/]+)\/.*/$2/;


my $scriptlist = "$keydir/scriptblock.txt";
my $pluginlist = "$keydir/pluginblock.txt";
my $scriptlist_temp = "$keydir/scriptblock_temp.txt";
my $pluginlist_temp = "$keydir/pluginblock_temp.txt";

`touch $scriptlist` if not -f $scriptlist;
`touch $scriptlist_temp` if not -f $scriptlist_temp;

`touch $pluginlist` if not -f $pluginlist;
`touch $pluginlist_temp` if not -f $pluginlist_temp;


sub to_fifo {
    my $cmd = shift;
    open(FIFO,">>$fifo");
    print FIFO $cmd;
    close(FIFO);
}

sub checklist {
    my $check_domain = shift;
    my $listkey = shift;
    my $list = $scriptlist;
    $list = $pluginlist if $listkey eq "plugin";
    return 1 if(`grep "$check_domain" $list | wc -l` > 0 );
    return 0;
}

sub add_to_list {
    my $listkey = shift;
    my $temp = shift;
    return unless $domain =~ /(http|https|ftp)/;
    if(checklist($domain,$listkey) == 0){
        my $list = $scriptlist;
        my $list_temp = $scriptlist_temp;
        if($listkey eq "plugin"){
            $list = $pluginlist;
            $list_temp = $pluginlist_temp;
        }

        open(FILE,">>$list");
        print FILE $domain."\n";
        close(FILE);

        if(defined $temp and $temp eq "temp"){
            open(FILE,">>$list_temp");
            print FILE $domain."\n";
            close(FILE);
        }
    }
}

sub remove_from_list {
    my $listkey = shift;
    my $list = $scriptlist;
    my $list_temp = $scriptlist_temp;
    if($listkey eq "plugin"){
        $list = $pluginlist;
        $list_temp = $pluginlist_temp;
    }
    $domain =~ s/\./\\./g;
    $domain =~ s/\//\\\//g;
    `sed "/$domain/d" -i $list`;
    `sed "/$domain/d" -i $list_temp`;
}

sub clear_temp {
    my @processes = `ps -e | grep uzbl-core`;
    if($#processes == -1){
        open(TEMPSCRIPTS,"<$scriptlist_temp");
        my @tempurls = <TEMPSCRIPTS>;
        close(TEMPSCRIPTS);
        foreach my $tempurl (@tempurls) {
            chomp $tempurl;
            $tempurl =~ s/\./\\./g;
            $tempurl =~ s/\//\\\//g;
            `sed "/$tempurl/d" -i $scriptlist` if checklist($tempurl,"script") == 1;
        }
        `> $scriptlist_temp`;

        open(TEMPPLUGINS,"<$pluginlist_temp");
        @tempurls = <TEMPPLUGINS>;
        close(TEMPPLUGINS);
        foreach my $tempurl (@tempurls) {
            chomp $tempurl;
            $tempurl =~ s/\./\\./g;
            $tempurl =~ s/\//\\\//g;
            `sed "/$tempurl/d" -i $pluginlist` if checklist($tempurl,"script") == 1;
        }
        `> $pluginlist_temp`;
    }
}

if($action eq ""){
    if(checklist($domain,"script") xor $whitelist == 1){
        to_fifo("set disable_scripts = 1\n");
        to_fifo("set scripts_status = <span foreground=\\\"#FF0000\\\">S</span>\n");
    } else {
        to_fifo("set disable_scripts = 0\n");
        to_fifo("set scripts_status = <span foreground=\\\"#00FF00\\\">S</span>\n");
    }
    if(checklist($domain,"plugin") xor $whitelist == 1){
        to_fifo("set disable_plugins = 1\n");
        to_fifo("set plugins_status = <span foreground=\\\"#FF0000\\\">P</span>\n");
    } else {
        to_fifo("set disable_plugins = 0\n");
        to_fifo("set plugins_status = <span foreground=\\\"#00FF00\\\">P</span>\n");
    }
} elsif($action eq 'unblock_scripts'){
    to_fifo("set disable_scripts = 0\n");
    if($whitelist == 1){
        add_to_list("script");
    } else {
        remove_from_list("script");
    }
} elsif($action eq 'unblock_scripts_temp'){
    to_fifo("set disable_scripts = 0\n");
    if($whitelist == 1){
        add_to_list("script","temp");
    } else {
        print "it doesn't make much sense to unblock scripts temporarily when using blacklists\n";
    }
} elsif($action eq 'unblock_plugins'){
    to_fifo("set disable_plugins = 0\n");
    if($whitelist == 1){
        add_to_list("plugin");
    } else {
        remove_from_list("plugin");
    }
} elsif($action eq 'unblock_plugins_temp'){
    to_fifo("set disable_plugins = 0\n");
    if($whitelist == 1){
        add_to_list("plugin","temp");
    } else {
        print "it doesn't make much sense to unblock plugins temporarily when using blacklists\n";
    }
} elsif($action eq 'block_scripts'){
    to_fifo("set disable_scripts = 1\n");
    if($whitelist == 1){
        remove_from_list("script");
    } else {
        add_to_list("script");
    }
} elsif($action eq 'block_scripts_temp'){
    to_fifo("set disable_scripts = 1\n");
    if($whitelist == 1){
        print "it doesn't make much sense to block scripts temporarily when using whitelists\n";
    } else {
        add_to_list("script","temp");
    }
} elsif($action eq 'block_plugins'){
    to_fifo("set disable_plugins = 1\n");
    if($whitelist == 1){
        remove_from_list("plugin");
    } else {
        add_to_list("plugin");
    }
} elsif($action eq 'block_plugins_temp'){
    to_fifo("set disable_plugins = 1\n");
    if($whitelist == 1){
        add_to_list("plugin","temp");
    } else {
        print "it doesn't make much sense to block plugins temporarily when using whitelists\n";
    }
} elsif($action eq 'clear_temp'){
    clear_temp();
}
