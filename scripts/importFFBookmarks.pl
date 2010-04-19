#!/usr/bin/perl

# This script converts Firefox Bookmarks into uzbl format. Tha tags are created from the folders where whitespaces are replaced with underscores.
# Double bookmarks are removed and the tags updated (so you get the tags of all folders where the url was saved)
#
# Usage:
# ./importFFBookmarks.pl /path/to/bookmarks.html > ~/.local/share/uzbl/bookmarks
# 
# Don't forget to update your current uzbl bookmarks or use 
# ./importFFBookmarks.pl /path/to/bookmarks.html >> ~/.local/share/uzbl/bookmarks

use strict;
use warnings;

my $filename = shift;

open(FILE,"<$filename");
my @lines = <FILE>;
close(FILE);

print "could not load $filename or file is empty" and exit if $#lines < 2;


my @tags = ();
my @bookmarks;

sub checkdouble {
    my $checkurl = shift;
    for(my $i=0;$i<=$#bookmarks;$i++) {
        my @fields = split(/ /,$bookmarks[$i]);
       if($fields[0] eq $checkurl){
           return $i
       }
    }
    return -1;
}

sub uniq {
    return keys %{{ map { $_ => 1 } @_ }};
}

sub update_bookmark {
    my $index = shift;
    my $newtags = shift;
    my $oldtags = $bookmarks[$index];
    $oldtags =~ s/[^\t]+\t\s*(.*)/$1/;
    $newtags = join(" ", uniq(split(/\s+/,$oldtags." ".$newtags)));
    $bookmarks[$index] =~ s/([^\t]+\t)\s*.*/$1$newtags/;
    chomp $bookmarks[$index];
}

    

# remove everything until first bookmark
my $line = $lines[0];
while(not $line =~ m/<DT>/){
    shift @lines;
    $line = $lines[0];
}


foreach $line (@lines) {
    chomp $line;
   if($line =~ m/<DT><H3/){
       my $tag = $line;
       $tag =~ s/.*<DT><H3[^>]+>([^<]+)<\/H3>/$1/;
       $tag =~ s/\s+/_/g;
       push(@tags,$tag);
   } elsif($line =~ m/<DT><A HREF/){
       my $bookmark = $line;
       $bookmark =~ s/.*<DT><A HREF="([^"]+)"[^>]+>([^<]+)<\/A>/$1 $2/;
       my $bookmark_tags = join(" ",@tags);
       chomp $bookmark_tags;
       my $index = checkdouble($1);
       if($index >= 0){
           update_bookmark($index,$bookmark_tags);
       } else {
           $bookmark .= "\t".$bookmark_tags;
           chomp $bookmark;
           push(@bookmarks,$bookmark);
       }
   } elsif($line =~ m/<\/DL><p>/){
       pop @tags;
   }

}

foreach $line (@bookmarks){
    print $line."\n";
}
