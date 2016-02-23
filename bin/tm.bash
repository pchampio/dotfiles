#!/bin/bash
# abort if we're already inside a TMUX session
[ "$TMUX" == "" ] || exit 0
# startup a "default" session if non currently exists
# tmux has-session -t _default || tmux new-session -s _default -d


SessionNb=$( tmux list-sessions -F "#S" 2>/dev/null | wc -l )
if [ $SessionNb -eq 0 ]; then
  read -p "Enter new session name: " SESSION_NAME
  TERM=screen-256color-bce tmux new -s "$SESSION_NAME"
else
  # present menu for user to choose which workspace to open
  PS3="Please choose your session: "
  options=($(tmux list-sessions -F "#S" 2>/dev/null) "New Session")
  echo "Available sessions"
  echo "------------------"
  echo " "
  select opt in "${options[@]}"
  do
    case $opt in
      "New Session")
        read -p "Enter new session name: " SESSION_NAME
        TERM=screen-256color-bce tmux new -s "$SESSION_NAME"
        break
        ;;
      *)
        TERM=screen-256color-bce tmux attach-session -t $opt
        break
        ;;
    esac
  done
fi
