#!/usr/bin/perl
#Control Cookie Script for uzbl
#
#This script checks whether a domain is in the cookie whitelist and colours a status symbol accordingly.
#Additionally it adds and removes pages from the whitelist (temporarily)
#
#USAGE:
#1)place this script in ~/.local/share/uzbl/scripts
#2)add the following to your ~/.config/uzbl/config:
#set cookie_color	  = #FF0000
#set cookie_status	 = <span foreground="\@cookie_color">C</span>
#set status_format	 = <span font_family="monospace">[...]@cookie_status</span>
#
#@on_event   LOAD_COMMIT	spawn @scripts_dir/cookies.pl
#
#set cookiescript = @scripts_dir/cookies.pl
#@cbind sbc = @cookiescript block
#@cbind suc = @cookiescript unblock
#@cbind stc = @cookiescript unblock_temp

use strict;
use warnings;

my $cookie_whitelist = "$ENV{HOME}/.local/share/uzbl/cookie_whitelist";
my $cookie_whitelist_temp = "$ENV{HOME}/.local/share/uzbl/cookie_whitelist_temp";

`touch $cookie_whitelist` if not -f $cookie_whitelist;
`touch $cookie_whitelist_temp` if not -f $cookie_whitelist_temp;

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

sub checklist {
    return 1 if(`grep "$url" $cookie_whitelist | wc -l` > 0 
    or `grep "$url" $cookie_whitelist_temp | wc -l` > 0);
    return 0;
}

sub clear_temp {
    open(TEMPFILE,"<$cookie_whitelist_temp");
    my @tempurls = <TEMPFILE>;
    close(TEMPFILE);
    foreach my $tempurl (@tempurls) {
        $url =~ s/\./\\./g;
        $url =~ s/\//\\\//g;
        `sed "/$url/d" -i $cookie_whitelist` if checklist() == 1;
    }
    `> $cookie_whitelist_temp`;
}

$action = "" if not defined $action;
$url =~ s/^(http|https):\/\/([^\/]+?)\/.*/$1:\/\/$2\//;

if($action eq ""){
    my $color_cmd = "set cookie_color = #00FF00\n";
    $color_cmd = "set cookie_color = #FF0000\n" if checklist() == 0;
    print "setting color to $color_cmd\n";
    open(FIFO,">>$fifo");
    print FIFO $color_cmd;
    close(FIFO);
} elsif($action eq "block") {
    print "blocking $url\n";
        $url =~ s/\./\\./g;
        $url =~ s/\//\\\//g;
        `sed "/$url/d" -i $cookie_whitelist`;
        `sed "/$url/d" -i $cookie_whitelist_temp`;
} elsif($action eq "unblock") {
    if(checklist() == 0){
    print "unblocking $url\n";
        open(FILE,">>$cookie_whitelist");
        print FILE $url."\n";
        close(FILE);
    }
} elsif($action eq "unblock_temp") {
    if(checklist() == 0){
    print "unblocking temporarily $url\n";
        open(FILE,">>$cookie_whitelist");
        print FILE $url."\n";
        close(FILE);
        open(TEMPFILE,">>$cookie_whitelist_temp");
        print TEMPFILE $url."\n";
        close(TEMPFILE);
    }
} elsif($action eq "clear_temp") {
    print "clearing temp\n";
    clear_temp();
}
