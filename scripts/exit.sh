#!/bin/bash
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

arg=$8

if [ "$arg" == 'prev' ]; then
    echo "event PREV_TAB" > $4
fi

echo "exit" > $4
