#! /bin/bash

WINTITLE="Gestionnaire de fichiers" # Main Thunderbird window has this in titlebar
PROGNAME="thunar" # This is the name of the binary for t-bird

# Use wmctrl to list all windows, count how many contain WINTITLE,
# and test if that count is non-zero:

if [ `wmctrl -l | grep -c "$WINTITLE"` != 0 ]
then
	wmctrl -a "$WINTITLE" # If it exists, bring t-bird window to front
else
	$PROGNAME & # Otherwise, just launch t-bird
fi
exit 0
