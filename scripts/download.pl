#!/usr/bin/perl
# An enhanced version of the download script supplied with uzbl
#
# Most ideas are from Pawel Tomaks downloads.sh script. See http://github.com/grodzik/uzbl-scripts
#
# To install, place this script to your scripts_dir and add the following line to your config:
#
# @on_event   DOWNLOAD_REQUEST    spawn @scripts_dir/download.pl %s

use strict;
use warnings;

# Some sites block the default wget --user-agent..
my $dl_prog="wget --user-agent=Firefox --content-disposition --load-cookies=$ENV{HOME}/.local/share/uzbl/cookies.txt -nv ";

# Put here message of wget if no data could be received (as my wget talks german to me I don't know the exact wording of the english version)
my $nodata = "keine daten empfangen";

my $dir="$ENV{HOME}/downloads/";
my $images="$ENV{HOME}/downloads/images";

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$dest) = @ARGV;

print "you must supply a url\n" and exit unless defined $dest;
print "you must supply a url\n" and exit if $dest eq "";

chdir $dir;
my $afile=`$dl_prog "$dest" 2>&1| sed 's/[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}[[:blank:]]\\+[0-9:]\\{8\\}[[:blank:]]\\+URL[^ ]\\+ \\[[0-9\\/]\\+\\][[:blank:]]\\+->[[:blank:]]\\+"\\([^"]\\+\\)".*\$/\\1/'`;
chomp $afile;

while($afile =~ m/$nodata/i){
    system("zenity --question --text=\"$afile\nTry again?\"");
    if($?){
        exit;
    } else {
        $afile=`$dl_prog "$dest" 2>&1| sed 's/[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}[[:blank:]]\\+[0-9:]\\{8\\}[[:blank:]]\\+URL[^ ]\\+ \\[[0-9\\/]\\+\\][[:blank:]]\\+->[[:blank:]]\\+"\\([^"]\\+\\)".*\$/\\1/'`;
        chomp $afile;
    }
}

my $bfile=$afile;
$bfile =~ s/(.*?)\?.*/$1/;
if($bfile =~ m/(gif|jpg|jpeg|png|bmp)/){
    $bfile="$images/$bfile";
}
if("$afile" ne "$bfile"){
    if(-e "$bfile"){
        # Todo: question the user if: overwrite, cancel download, other filename
        $bfile="$bfile".`ls "$bfile"*|wc -l`;
    }
    `mv "$afile" "$bfile"`;
}
`notify-send "Downloaded" "$bfile"`;
