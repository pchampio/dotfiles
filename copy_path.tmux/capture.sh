# !/usr/bin/env bash

get_current_pane_info() {
  tmux display -p '#{pane_id} #{pane_pid}'
}

get_current_pane_id() {
  get_current_pane_info | awk '{ print $1 }'
}

get_pane_pid_from_pane_id() {
  tmux list-panes -F "#{pane_id} #{pane_pid}" | awk "/^$1 / { print \$2}"
}

_ssh_command() {
  local child_cmd
  local pane_id
  local pane_pid

  pane_id="${1:-$(get_current_pane_id)}"
  pane_pid="$(get_pane_pid_from_pane_id "$pane_id")"

  if [[ -z "$pane_pid" ]]
  then
    echo "Could not determine pane PID" >&2
    return 3
  fi

  ps -o command= -g "${pane_pid}" | while read -r child_cmd
  do
    if [[ "$child_cmd" =~ ^(auto)?ssh ]]
    then
      # Filter out "ssh -W"
      if ! grep -qE "ssh.*\s+-W\s+" <<< "$child_cmd"
      then
        echo "$child_cmd"
        return
      fi
    fi
  done

  return 1
}

_capture_pane() {
    local pane captured
    captured=""

    if [[ $grab_area =~ ^window\  ]]; then
        for pane in $(tmux list-panes -F "#{pane_active}:#{pane_id}"); do
            # exclude the active (for split) and trigger panes
            # in popup mode the active and tigger panes are the same
            if [[ $pane =~ ^0: && ${pane:2} != "$trigger_pane" ]]; then
                captured+="$(tmux capture-pane -pJS ${capture_pane_start} -t ${pane:2})"
                captured+=$'\n'
            fi
        done
    fi

    captured+="$(tmux capture-pane -pJS ${capture_pane_start} -t $trigger_pane)"

    echo "$captured"
}

ssh_command="$(_ssh_command)"
if [[ -z "$ssh_command" ]]
then
    tmux set-buffer -- $(tmux run pwd)
else
    echo "EST,"
    path=$(_capture_pane | tac | grep --max-count 1 "^\$~" -A 1 | sed -n '2 p' | awk '{match($0,/\/[^"]*/,a);print a[0]}' | sed "s/$(git rev-parse --abbrev-ref HEAD).*//")
    echo $path
    tmux set-buffer -- "$path"
fi
