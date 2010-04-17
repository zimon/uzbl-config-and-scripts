#!/bin/bash

if [ -e "$XDG_DATA_HOME/uzbl/histlock" ]; then
    #echo "no hist -> no undo"
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

arg=$8

if [ "$arg" == 'prev' ]; then
    echo "event PREV_TAB" > $4
fi

echo "exit" > $4
