#!/bin/bash

# This is a modified version of the exti/undo script from http://www.uzbl.org/wiki/undo for using with uzbl-tabbed.
# Restored Tabs are opened to left of the current tab.

UNDO="$XDG_DATA_HOME/uzbl/undolist"
if [ -e $UNDO ]; then
    URL=`tail -n 1 $UNDO`
    LINECOUNT=`cat $UNDO | wc -l`
    if [[ $LINECOUNT == 1 ]]; then
        echo "event NEW_TAB_NEXT $URL" > $4 &
        rm $UNDO
    else
        echo "event NEW_TAB_NEXT $URL" > $4 &
        sed -i '$d' $UNDO
    fi
fi
