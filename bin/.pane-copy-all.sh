#!/usr/bin/env sh

STATE_FILE="${HOME}/.cache/pane-copy-all.state"

# Gather a list of all pane IDs and which are currently in copy-mode (pane_in_mode=1)
# Format: pane_id pane_in_mode
all_status=$(tmux list-panes -F "#{pane_id} #{pane_in_mode}")

if [ ! -f "$STATE_FILE" ]; then
  # === FIRST PRESS ===
  # 1) Record the ones already in copy-mode
  echo "$all_status" \
    | awk '$2 == 1 { print $1 }' \
    > "$STATE_FILE"

  # 2) Enter copy-mode on every pane
  echo "$all_status" \
    | awk '{ print $1 }' \
    | while read -r p; do
        tmux copy-mode -H -t "$p"
      done

else
  # === TOGGLE BACK ===
  # Read the list of panes that were originally in copy-mode
  ORIGINAL=$(cat "$STATE_FILE")

  # For every pane that is _currently_ in copy-mode but wasn’t in ORIGINAL, exit it
  echo "$all_status" \
    | awk '$2 == 1 { print $1 }' \
    | while read -r p; do
        # Check if $p is _not_ in ORIGINAL
        if ! echo "$ORIGINAL" | grep -q "^${p}\$"; then
          tmux send-keys -t "$p" -X cancel
        fi
      done

  # Clean up
  rm -f "$STATE_FILE"
fi

