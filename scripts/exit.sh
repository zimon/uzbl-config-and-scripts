#!/bin/bash

# This is a modified version of the exti/undo script from http://www.uzbl.org/wiki/undo for using with uzbl-tabbed.
# URLs are only added to undo-file if history is not locked (see history.pl script).
#
# See also undo.sh for recovering tabs closed with this script.
# 
# To install, place this script at your scripts_dir and add the following lines to your config: 
# 
# @cbind  d  = spawn \@scripts_dir/exit.sh       # exit current tab and switch to the tab right
# @cbind  D  = spawn \@scripts_dir/exit.sh prev  # exit current tab and switch to the tab left
#

arg=$8

if [ -e "$XDG_DATA_HOME/uzbl/histlock" ]; then
    if [ "$arg" == 'prev' ]; then
        echo "event PREV_TAB" > $4
    fi
    echo "exit" > $4

    exit
fi

UNDO="$XDG_DATA_HOME/uzbl/undolist"
if [ -e $UNDO ]; then
    #echo "to undo $6"
    LINECOUNT=`cat $UNDO | wc -l`
    if [ $LINECOUNT -ge 100 ]; then
        sed -i "1d" $UNDO
    fi
fi

if [ $6 != "" ]; then
    echo "$6" >> $UNDO
fi


if [ "$arg" == 'prev' ]; then
    echo "event PREV_TAB" > $4
fi

echo "exit" > $4
