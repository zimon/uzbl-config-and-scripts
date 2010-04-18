#!/usr/bin/perl
#
# Enhanced html form (eg for logins) filler (and manager) for uzbl.
#
# uses settings files like: $keydir/<domain>
# files contain lines like: !profile=<profile_name>
#                           <fieldname>(fieldtype): <value>
# profile_name should be replaced with a name that will tell sth about that profile
# fieldtype can be text or password - only for information pupropse (auto-generated) - don't change that
#
# user arg 1:
# edit: force editing the file (falls back to new if not found)
# new:  start with a new file.
# load: try to load from file into form
# add: try to add another profile to an existing file
#
# something else (or empty): if file not available: new, otherwise load.

use strict;
use warnings;

# config dmenu colors and prompt
my $NB="#0f0f0f";
my $NF="#4e7093";
my $SB="#003d7c";
my $SF="#3a9bff";

my $editor='xterm -bg black -fg green -fn 8x16 -e vim';

my $LINES = "";

$LINES=" -l 3 " unless `dmenu --help 2>&1| grep lines`."x" eq "x";

my $PROMPT="Choose profile ";

my $keydir=$ENV{HOME}."/.local/share/uzbl/dforms";

#exit if -d `dirname $keydir`;
mkdir $keydir unless -d $keydir;


my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

mkdir $keydir unless -d $keydir;
exit unless -d $keydir;

my $domain = $url;
$domain =~ s/(http|https):\/\/([^\/]+)\/.*/$2/;
$domain =~ s/\//_slash_/g;


sub get_form_fields {
    my $filename = shift;

    my $html=`echo 'js if(window.frames.length > 0) { for(i=0;i<window.frames.length;i=i+1) { window.frames[i].document.documentElement.outerHTML } }' | socat - unix-connect:$socket`;
        $html .= " ".`echo 'js document.documentElement.outerHTML' | socat - unix-connect:$socket`;
    $html =~ s/<!--.*?-->//gs; # remove comments
    $html =~ s/\n//sg; # remove newlines
    $html =~ s/^.*?</</; # remove all but tags
    $html =~ s/^.*?(<input[^<>]+type[^<>]+>)/$1/; # remove everything until first input tag
    $html =~ s/.*?(<input[^<>]+type[^<>]+>).*?/$1/g; # remove everything but input tag
    $html =~ s/(.*<input[^<>]+type[^<>]+>).*/$1/g; # remove everything after input tags
    $html =~ s/<input[^<>]+type="hidden"[^<>]+>//g; # remove hidden tags
    $html =~ s/<input[^<>]+type="submit"[^<>]+>//g; # remove submit tag
    $html =~ s/>.*?</>\n</g; # each tag in an own line
    $html =~ s/name="([^"]+)"(.*)type="([^"]+)"(.*)/type="$3"$2name="$1"$4/g; # switch name and type if name is first
    $html =~ s/.*type="([^"]+)".*name="([^"]+)".*/$2($1): /g; # create output when type first

    open(FILE,">>$filename");
    print FILE "$html";
    close(FILE);

    #`echo "$html2" | sed -n 's/.*<textarea.*name="\\\([^"]\\\+\\\)".*/\\\1(textarea): /Ip' >> $filename`;
}

sub fill_form_fields {
    my @entries = @_;

    my $js = "";
    foreach my $item (@entries) {
        my ($name,$type,$value) = ($item =~ m/(.*?)\(([^\)]+)\):\s+(.*)/);
        if($type ne "checkbox"){
            $js .= "js if(window.frames.length > 0) { 
                for(i=0;i<window.frames.length;i=i+1) { 
                    var e = window.frames[i].document.getElementsByName(\\\"$name\\\");
                    if(e.length > 0) { 
                        e[0].value=\\\"$value\\\" 
                    } 
                } 
        }; document.getElementsByName(\\\"$name\\\")[0].value=\\\"$value\\\"__newline__";
        } else {
            my $check = "false";
            $check = "true" if $value eq "checked" || $value eq "selected" || $value eq "checked" || $value eq "true";
            $js .= "js if(window.frames.length > 0) { 
                for(i=0;i<window.frames.length;i=i+1) { 
                    var e = window.frames[i].document.getElementsByName(\\\"$name\\\");
                    if(e.length > 0) { 
                        e[0].checked=$check
                    } 
                } 
        }; document.getElementsByName(\\\"$name\\\")[0].checked=$check __newline__";
        }
    }

    $js =~ s/\@/\\\\@/g;
    $js =~ s/\n//g;
    $js =~ s/\s+/ /g;
    $js =~ s/__newline__/\n/g;
    open(FIFO,">>$fifo");
    print FIFO $js."\n";
    close(FIFO);
}


if($action ne 'edit' and  $action ne 'new' and $action ne 'load' and $action ne 'add' and $action ne 'once'){
    $action="new";
    $action = "load" if -f "$keydir/$domain";
} elsif($action eq 'edit' and not -f "$keydir/$domain"){
    $action="new";
}

if($action eq 'load'){
    exit 2 unless -e "$keydir/$domain";
    my $option = "";
    open(MENU,"<$keydir/$domain");
    my @menulines = <MENU>;
    close(MENU); 
    exit unless @menulines;
    my $menu = join("\n",@menulines);
    my @num_profiles = ($menu =~ m/(!profile)/g);
    if($#num_profiles > 0){
        $menu =~ s/\n+/\n/g; # remove empty lines
        $menu =~ s/(!profile=[^\s]+).*\n!/$1\n!/sg;
        $menu =~ s/(.*!profile=[^\s]+).*?$/$1/sg;
        $menu =~ s/!profile=([^\s]+)/$1/g;
        $option=`echo "$menu"| dmenu $LINES -nb "$NB" -nf "$NF" -sb "$SB" -sf "$SF" -p "$PROMPT"`;
    }
    my $entry = join("\n",@menulines);
    $entry =~ s/.*(!profile=$option.*?)($|!profile.*)/$1/s;
    $entry =~ s/\n+/\n/g; # remove empty lines
    $entry =~ s/!profile=$option.*?\n//;
    my @entries = split(/\n/,$entry);
    fill_form_fields(@entries);
} else {
    if($action eq 'new' or $action eq 'add'){
        my $RANDOM = int(rand(100000));
        if($action eq 'new'){
            `echo "!profile=NAME_THIS_PROFILE$RANDOM" > $keydir/$domain`;
        } else {
            `echo "!profile=NAME_THIS_PROFILE$RANDOM" >> $keydir/$domain`;
        }
        get_form_fields("$keydir/$domain");
    }
    exit 3 unless -e "$keydir/$domain"; #this should never happen, but you never know.

    `$editor $keydir/$domain`; #TODO: if user aborts save in editor, the file is already overwritten
}

