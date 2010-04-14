#!/bin/sh
UNDO="$XDG_DATA_HOME/uzbl/undolist"
if [ -e $UNDO ]; then
    LINECOUNT=`cat $UNDO | wc -l`
    if [ $LINECOUNT -ge 100 ]; then
        sed -i "1d" $UNDO
    fi
fi
if [ $6 != "" ]; then
    echo "$6" >> $UNDO
fi
