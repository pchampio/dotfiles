#!/usr/bin/env sh

pgrep "spotify"
RESULT=$?
if [ $RESULT -eq 0 ]; then
  dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
else
  spotify-wrapper.sh
fi
