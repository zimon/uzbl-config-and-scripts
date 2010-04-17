#!/usr/bin/perl
#
# an alternative session script
#
# Default session is stored as "default_session_file"
# 
# Attention: When session to save as already exists it will be overwritten without prompting the user
#
# To install just place this file at your scripts-dir and set up (at least some of) the following bindings:
# 
#set session = spawn @scripts_dir/sessions.pl
#@cbind  so<Session:>_   = @session open %s                 # open session with name
#@cbind  sdo             = @session open                    # open default session
#@cbind  sq              = @session open query_session_file # open and query for session
#@cbind  ss<Session:>_   = @session save %s                 # save session as
#@cbind  sds             = @session save                    # save session as default
#@cbind  sc<Session:>_   = @session save_and_quit %s        # save session as and quit
#@cbind  sdc             = @session save_and_quit           # save session as default and quit
#@cbind  sQ              = @session kill                    # quit all without saving
#
###

use warnings;
use strict;

### Arguments
my ($config,$pid,$xid,$fifo,$socket,$url,$title,$action,$session_file) = @ARGV;

# config dmenu colors and prompt
my $NB="#0f0f0f";
my $NF="#4e7093";
my $SB="#003d7c";
my $SF="#3a9bff";

my $LINES = "";

$LINES=" -l 3 " unless `dmenu --help 2>&1| grep lines`."x" eq "x";

### Constants
my $event = "NEW_TAB"; # set event NEW_TAB or NEW_WINDOW
my $this_script = $0;
my $fifo_dir='/tmp';
my $default_session_file="default_session";
my $sessiondir="$ENV{HOME}/.local/share/uzbl/sessions";

mkdir $sessiondir unless -d $sessiondir;


### Session functions
# this may not be needed as the project
# matures, but it doesn't hurt anyway
sub cleanup {#{{{
# kill any zombies
    my @pids = `pgrep uzbl`;
    foreach my $pid (@pids) {
        chomp $pid;
        `kill $pid`;
    }

# remove some trash
    `rm -rf $fifo_dir/uzbl_socket_*`;
    `rm -rf $fifo_dir/uzbl_fifo_*`;
}
#}}}

# save instance
sub save_instance {
    `echo "$url" >> $sessiondir/$session_file` if $url =~ m/(http|https|file):\/\/.+/;
}

# quit all, save uris
sub save_and_quit {
    unlink "$sessiondir/$session_file";

    my @fifos = `ls $fifo_dir/uzbl_fifo_*`;
    foreach my $actual_fifo (@fifos) {
        chomp $actual_fifo;
        `echo "spawn $this_script save_instance $session_file" >> "$actual_fifo"` if $fifo ne "$actual_fifo";
        `echo "exit" >> "$actual_fifo"` if $fifo ne "$actual_fifo";
    }
    `echo "spawn $this_script save_instance $session_file" >> "$fifo"`;
    `echo "exit" >> "$fifo"`;

    cleanup();
}

# save all, don't quit
sub save_session {
    unlink "$sessiondir/$session_file";

    my @fifos = `ls $fifo_dir/uzbl_fifo_*`;
    foreach my $actual_fifo (@fifos) {
        chomp $actual_fifo;
        `echo "spawn $this_script save_instance $session_file" >> "$actual_fifo"` if $fifo ne "$actual_fifo";
    }
    `echo "spawn $this_script save_instance $session_file" >> $fifo`;
}

# quit all, no save
sub kill_session {
    my @fifos = `ls $fifo_dir/uzbl_fifo_*`;
    foreach my $actual_fifo (@fifos) {
        chomp $actual_fifo;
        `echo "exit" >> $actual_fifo`;
    }
    cleanup();
}

# open uzbl
sub open_session {
    if($session_file eq "query_session_file"){
# query with dmenu
        my $PROMPT="Choose session file ";
        my $option = `ls $sessiondir | dmenu $LINES -nb "$NB" -nf "$NF" -sb "$SB" -sf "$SF" -p "$PROMPT"`;
        $session_file = $option if -f "$sessiondir/$option";
    }
    open(FILE,"<$sessiondir/$session_file");
    my @urls = <FILE>;
    close(FILE);
    exit unless @urls;

    for(my $i=0;$i<$#urls;$i++){
        next if $urls[$i] eq "";
        `echo "event $event $urls[$i]" >> $fifo`;
    }
    `echo "uri $urls[$#urls]" >> $fifo`;
}


$session_file = $default_session_file if not defined $session_file or $session_file eq "";
if($action eq "save"){
    save_session();
} elsif($action eq "save_and_quit"){
    save_and_quit()
} elsif($action eq "save_instance"){
    save_instance()
} elsif($action eq "open"){
    open_session();
} elsif($action eq "kill"){
    kill_session();
}


# for a better use with vim. All the markings: #{{{ and #}}} belong to it
# vim: foldmethod=marker commentstring=#%s
