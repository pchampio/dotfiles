#!/usr/bin/env bash

# copy current directory to clipboard
bind . run "tmux set-buffer -- $(tmux run pwd)"
# CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# tmux bind-key . run-shell "$CURRENT_DIR/capture.sh"
