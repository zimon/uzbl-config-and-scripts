#!/usr/bin/perl
# Control Cookie Script for uzbl
#
# Most ideas of this script are from isildurs checkcookie.py and cookie2whitelist.py scripts. See http://gist.github.com/340037
#
# This script checks whether a domain is in the cookie whitelist and colours a status symbol accordingly.
# Additionally it adds and removes pages from the whitelist (temporarily)
#
# To remove the temporarily whitelisted domains from the whitelist this script should be called with argument clear_temp. 
# As the INSTANCE_EXIT event doesn't work for me I use the uzbl script to start uzbl-tabbed (or uzbl-browser) which calls this script when uzbl was closed
# 
# To install, place this script in your scripts_dir and add the following lines to your config
# set cookie_color	  = #FF0000
# set cookie_status	 = <span foreground="\@cookie_color">C</span>
# set status_format	 = <span font_family="monospace">[...]@cookie_status</span>
# 
# @on_event   LOAD_COMMIT	spawn @scripts_dir/cookies.pl
# 
# set cookiescript = @scripts_dir/cookies.pl
# @cbind sbc = @cookiescript block
# @cbind suc = @cookiescript unblock
# @cbind stc = @cookiescript unblock_temp

use strict;
use warnings;

my $cookie_whitelist = "$ENV{HOME}/.local/share/uzbl/cookie_whitelist";
my $cookie_whitelist_temp = "$ENV{HOME}/.local/share/uzbl/cookie_whitelist_temp";


`touch $cookie_whitelist` if not -f $cookie_whitelist;
`touch $cookie_whitelist_temp` if not -f $cookie_whitelist_temp;

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

sub checklist {
    my $check_url = shift;
    return 1 if(`grep "$check_url" $cookie_whitelist | wc -l` > 0 );
    return 0;
}

sub clear_temp {
    my @processes = `ps -e | grep uzbl-core`;
    if($#processes == -1){
        open(TEMPFILE,"<$cookie_whitelist_temp");
        my @tempurls = <TEMPFILE>;
        close(TEMPFILE);
        foreach my $tempurl (@tempurls) {
            chomp $tempurl;
            $tempurl =~ s/\./\\./g;
            $tempurl =~ s/\//\\\//g;
            `sed "/$tempurl/d" -i $cookie_whitelist` if checklist($tempurl) == 1;
        }
        `> $cookie_whitelist_temp`;
    }
}

$action = "" if not defined $action;
$url =~ s/^(http|https):\/\/([^\/]+?)\/.*/$2/;

if($action eq ""){
    my $status_cmd = "set cookie_status = <span foreground=\\\"#00FF00\\\">C</span>\n";
    $status_cmd = "set cookie_status = <span foreground=\\\"#FF0000\\\">C</span>\n" if checklist($url) == 0;
    open(FIFO,">>$fifo");
    print FIFO $status_cmd;
    close(FIFO);
} elsif($action eq "block") {
        $url =~ s/\./\\./g;
        $url =~ s/\//\\\//g;
        `sed "/$url/d" -i $cookie_whitelist`;
        `sed "/$url/d" -i $cookie_whitelist_temp`;
} elsif($action eq "unblock") {
    if(checklist($url) == 0){
        open(FILE,">>$cookie_whitelist");
        print FILE $url."\n";
        close(FILE);
    }
} elsif($action eq "unblock_temp") {
    if(checklist($url) == 0){
        open(FILE,">>$cookie_whitelist");
        print FILE $url."\n";
        close(FILE);
        open(TEMPFILE,">>$cookie_whitelist_temp");
        print TEMPFILE $url."\n";
        close(TEMPFILE);
    }
} elsif($action eq "clear_temp") {
    clear_temp();
}
