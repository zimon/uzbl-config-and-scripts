#!/bin/bash
UNDO="$XDG_DATA_HOME/uzbl/undolist"
if [ -e $UNDO ]; then
    URL=`tail -n 1 $UNDO`
    LINECOUNT=`cat $UNDO | wc -l`
    if [[ $LINECOUNT == 1 ]]; then
        echo "event NEW_TAB $URL" > $4 &
        rm $UNDO
    else
        echo "event NEW_TAB $URL" > $4 &
        sed -i '$d' $UNDO
    fi
fi
