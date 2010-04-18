#!/bin/bash
# YouTube Video Player
# Required: uzbl, youtube-dl, mplayer or vlc
# 
# This is a modified version of the ytvp.sh script from http://www.uzbl.org/wiki/ytvp
# As playing the youtube_dl link with vlc didn't work for me I start downloading it to a temporary file and then playing it with vlc.
#
# TODO: kill youtube-dl and remove temp-file if player is closed.


# Uncomment one of these modes.
FORMATS=()   # Play SD quality.
#FORMATS=(22 18 6) # Play best HD quality available.
#FORMATS=(6 18 22) # Play worst HD quality available.

# Settings
#PLAYER_COMMAND=(mplayer -really-quiet -fs)
PLAYER_COMMAND=(vlc)
VALID_URL=0
exec &>/dev/null

# This is not necessaty because of the scriptblock.pl script
#
# Disable browser plugins on video pages.
#if echo "$6" | grep "http://www.youtube.com"; then
#  echo "set disable_plugins = 1" > "$4"
#else
#  echo "set disable_plugins = 0" > "$4"
#fi

# Plays the first format found.
if fgrep 'http://www.youtube.com/watch' -q <<< "$6"; then
  VALID_URL=1
  for f in "${FORMATS[@]}"; do
    URL=$(youtube-dl -f "$f" -g "$6")
    if [[ $URL ]] ; then
      youtube-dl -f "$f" -o /tmp/youtube_temp.flv "$6" &
      sleep 3
      "${PLAYER_COMMAND[@]}" /tmp/youtube_temp.flv "$6" &
      exit
    fi
  done
fi

if [[ $VALID_URL = 1 ]]; then
      youtube-dl -o /tmp/youtube_temp.flv "$6" &
      sleep 3
      "${PLAYER_COMMAND[@]}" /tmp/youtube_temp.flv "$6" &
fi
