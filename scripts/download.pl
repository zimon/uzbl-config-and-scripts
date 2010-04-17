#!/usr/bin/perl
# An enhanced version of the download script supplied with uzbl

use strict;
use warnings;

# Some sites block the default wget --user-agent..
my $dl_prog="wget --user-agent=Firefox --content-disposition --load-cookies=$ENV{HOME}/.local/share/uzbl/cookies.txt -nv ";

my $dir="$ENV{HOME}/downloads/";
my $images="$ENV{HOME}/downloads/images";

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$dest) = @ARGV;

print "you must supply a url\n" and exit unless defined $dest;
print "you must supply a url\n" and exit if $dest eq "";

chdir $dir;
my $afile=`$dl_prog "$dest" 2>&1| sed 's/[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}[[:blank:]]\\+[0-9:]\\{8\\}[[:blank:]]\\+URL[^ ]\\+ \\[[0-9\\/]\\+\\][[:blank:]]\\+->[[:blank:]]\\+"\\([^"]\\+\\)".*\$/\\1/'`;
chomp $afile;

while($afile =~ m/keine daten empfangen/i){
    system("zenity --question --text=\"$afile\nNochmal versuchen?\"");
    if($?){
        #print "no answered\n";
        exit;
    } else {
        #print "yes answered\n";
        $afile=`$dl_prog "$dest" 2>&1| sed 's/[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}[[:blank:]]\\+[0-9:]\\{8\\}[[:blank:]]\\+URL[^ ]\\+ \\[[0-9\\/]\\+\\][[:blank:]]\\+->[[:blank:]]\\+"\\([^"]\\+\\)".*\$/\\1/'`;
        chomp $afile;
    }
}

my $bfile=$afile;
$bfile =~ s/(.*?)\?.*/$1/;
#print "afile: $afile\nbfile: $bfile\n";
if($bfile =~ m/(gif|jpg|jpeg|png|bmp)/){
    #print "image so set $bfile to $images/$bfile\n";
    $bfile="$images/$bfile";
}
if("$afile" ne "$bfile"){
    if(-e "$bfile"){
#todo gtk question: overwrite, cancel download, other filename
        $bfile="$bfile".`ls "$bfile"*|wc -l`;
    }
    #print "moving $afile to $bfile\n";
    `mv "$afile" "$bfile"`;
}
`notify-send "Downloaded" "$bfile"`;
