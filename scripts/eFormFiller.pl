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

my $LINES = "";

$LINES=" -l 3 " unless `dmenu --help 2>&1| grep lines`."x" eq "x";

my $PROMPT="Choose profile ";

my $keydir=$ENV{HOME}."/.local/share/uzbl/dforms";

#exit if -d `dirname $keydir`;
mkdir $keydir unless -d $keydir;

my $editor='xterm -e vim';

my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action) = @ARGV;

#[ -d $keydir ] || mkdir $keydir || exit 1

my $domain = $url;
$domain =~ s/(http|https):\/\/(.+)\/($|.+\..{2,4}|.*?\?.*)/$2/;
$domain =~ s/\//_slash_/g;
#print "file: $keydir/$domain\n";

#print "args: @ARGV\n";

if($action ne 'edit' and  $action ne 'new' and $action ne 'load' and $action ne 'add' and $action ne 'once'){
    $action="new";
    $action = "load" if -f "$keydir/$domain";
} elsif($action eq 'edit' and not -f "$keydir/$domain"){
    $action="new";
}

if($action eq 'load'){
    exit 2 unless -e "$keydir/$domain";
    my $option = "";
    if(`cat $keydir/$domain|grep "!profile"|wc -l` > 1){
#        print "mehr als 1 eintrag\n";
        #my $menu=`cat $keydir/$domain | sed -n 's/^!profile=\\([^[:blank:]]\\+\\)/\\1/p'`;
        open(MENU,"<$keydir/$domain");
        my @menulines = <MENU>;
        close(MENU); 
        my $menu = join("\n",@menulines);
        $menu =~ s/.*text.*\n//g;
        $menu =~ s/.*password.*\n//g;
        $menu =~ s/\n+/\n/g; # remove empty lines
        $menu =~ s/!profile=([^\s]+)/$1/g;
        $option=`echo "$menu"| dmenu $LINES -nb "$NB" -nf "$NF" -sb "$SB" -sf "$SF" -p "$PROMPT"`;
    }

    `cat $keydir/$domain | sed -n -e "/^!profile=$option/,/^!profile=/p" | sed -n -e 's/\\([^(]\\+\\)([^)]\\+):[ ]*\\([^[:blank:]]\\+\\)/js if(window.frames.length > 0) { for(i=0;i<window.frames.length;i=i+1) { var e = window.frames[i].document.getElementsByName("\\1"); if(e.length > 0) { e[0].value="\\2" } } }; document.getElementsByName("\\1")[0].value="\\2"/p' | sed -e 's/@/\\\\@/g' >> $fifo`;
#} elsif($action eq "once"){
#    my $tmpfile = `mktemp`;
#    my $html = `echo 'js if(window.frames.length > 0) { for(i=0;i<window.frames.length;i=i+1) { window.frames[i].document.documentElement.outerHTML } }' | socat - unix-connect:$socket`;
#    $html .= " ".`echo 'js document.documentElement.outerHTML' | socat - unix-connect:$socket`;
#    $html=`echo $html | 
#            tr -d '\\n' | 
#            sed 's/>/>\\n/g' | 
#            sed 's/<input/<input type="text"/g' | 
#            sed 's/type="text"\\(.*\\)type="\\([^"]\\+\\)"/type="\\2" \\1 /g'`;
#    `echo "$html" | 
#        sed -n 's/.*\\(<input[^>]\\+>\\).*/\\1/;/type="\\(password\\|text\\)"/Ip' | 
#        sed 's/\\(.*\\)\\(type="[^"]\\+"\\)\\(.*\\)\\(name="[^"]\\+"\\)\\(.*\\)/\\1\\4\\3\\2\\5/I' | 
#        sed 's/.*name="\\([^"]\\+\\)".*type="\\([^"]\\+\\)".*/\\1(\\2): /I' >> $tmpfile`;
#    `echo "$html" | sed -n 's/.*<textarea.*name="\\([^"]\\+\\)".*/\\1(textarea): /Ip' >> $tmpfile`;
#    `$editor $tmpfile`;
#
#    exit 2 unless -e $tmpfile;
#
#    `cat $tmpfile | 
#        sed -n -e 's/\\([^(]\\+\\)([^)]\\+):[ ]*\\([^[:blank:]]\\+\\)/js if(window.frames.length > 0) { for(i=0;i<window.frames.length;i=i+1) { var e = window.frames[i].document.getElementsByName("\\1"); if(e.length > 0) { e[0].value="\\2" } } }; document.getElementsByName("\\1")[0].value="\\2"/p' | \
#        sed -e 's/@/\\\\@/g' >> $fifo`;
#    unlink $tmpfile;
} else {
    if($action eq 'new' or $action eq 'add'){
        my $RANDOM = int(rand(100000));
#        print "$RANDOM\n";
        if($action eq 'new'){
            `echo "!profile=NAME_THIS_PROFILE$RANDOM" > $keydir/$domain`;
        } else {
            `echo "!profile=NAME_THIS_PROFILE$RANDOM" >> $keydir/$domain`;
        }
    #
    # 2. and 3. line (tr -d and sed) are because, on gmail login for example, 
    # <input > tag is splited into lines
    # ex:
    # <input name="Email"
    #        type="text"
    #        value="">
    # So, tr removes all new lines, and sed inserts new line after each >
    # Next sed selects only <input> tags and only with type == "text" or == "password"
    # If type is first and name is second, then another sed will change their order
    # so the last sed will make output 
    #       text_from_the_name_attr(text or password): 
    #
    #       login(text):
    #       passwd(password):
    #
#    print "before html stuff\n";
        my $html=`echo 'js if(window.frames.length > 0) { for(i=0;i<window.frames.length;i=i+1) { window.frames[i].document.documentElement.outerHTML } }' | socat - unix-connect:$socket`;
        #print "html: $html\n";
#    print "after first html command\n";
        $html .= " ".`echo 'js document.documentElement.outerHTML' | socat - unix-connect:$socket`;
#    print "after second html command\n";
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
    open(FILE,">>$keydir/$domain");
    print FILE $html;
    close(FILE);
#    print "after last html command\n";
    }
    exit 3 unless -f "$keydir/$domain"; #this should never happen, but you never know.

#    print "before calling vi: $editor $keydir/$domain\n";
    `$editor $keydir/$domain`; #TODO: if user aborts save in editor, the file is already overwritten
}

