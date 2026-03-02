#!/bin/bash
# Distribute window tabs across bottom panes left-to-right.
# Each bottom pane (sorted by x position) gets as many complete tabs
# as fit its width, then the next pane picks up where it left off.
#
# Pre-computes @pane_tabs for ALL windows (list-panes -a), so switching to
# any window shows correct tabs immediately — no stale content flash.
#
# Called by tmux hooks (layout-changed, resized, split, focus, rename, etc.)
# and once at startup. Writes a tmux format string into the per-pane option
# @pane_tabs, which pane-border-format evaluates via #{E:#{@pane_tabs}}.
# Active tab highlighting uses #{?#{==:IDX,#{window_index}},...} conditionals
# resolved at render time — no script delay for window-switch highlighting.
#
# Color constants below must stay in sync with WINDOW_STATUS_FMT /
# WINDOW_STATUS_CURRENT_FMT in tmux.conf.

BG="#fbf3db"
BORDER_OVERHEAD=2
MAX_CMD_BYTES=8192

IDX_FG_I="colour8"
IDX_BG_I="colour59"
NAME_FG_I="colour58"
NAME_BG_I="colour188"

IDX_FG_A="colour7"
IDX_BG_A="colour124"
NAME_FG_A="colour59"
NAME_BG_A="colour188"

# --- Single tmux call for both queries (-a = all panes across all windows) ---
data=$(tmux list-windows -F "W	#{window_index}	#{window_name}	#{window_zoomed_flag}	#{pane_synchronized}" \; \
       list-panes -a -F "P	#{pane_id}	#{pane_at_bottom}	#{pane_width}	#{pane_left}	#{window_id}" 2>/dev/null)

[[ -z "$data" ]] && exit 0

# --- Parse query results ---
win_idx=()
win_name=()
win_zoomed=()
win_synced=()

pane_ids=()
pane_at_bottom=()
pane_widths=()
pane_lefts=()
pane_win_ids=()

while IFS=$'\t' read -r type f1 f2 f3 f4 f5; do
    case "$type" in
        W) win_idx+=("$f1"); win_name+=("$f2"); win_zoomed+=("$f3"); win_synced+=("$f4") ;;
        P) pane_ids+=("$f1"); pane_at_bottom+=("$f2"); pane_widths+=("$f3"); pane_lefts+=("$f4"); pane_win_ids+=("$f5") ;;
    esac
done <<< "$data"

total_tabs=${#win_idx[@]}
total_panes=${#pane_ids[@]}
[[ $total_tabs -eq 0 || $total_panes -eq 0 ]] && exit 0

# --- Compute visible width and format string for each tab ---
# #, = escaped comma inside #{?...} branches so tmux doesn't split on them.
tab_width=()
tab_str=()

for ((i = 0; i < total_tabs; i++)); do
    idx="${win_idx[$i]}"
    name="${win_name[$i]}"

    flags=""
    flags_w=0
    [[ "${win_zoomed[$i]}" == "1" ]] && { flags+="Z "; flags_w=$((flags_w + 2)); }
    [[ "${win_synced[$i]}" == "1" ]] && { flags+="S "; flags_w=$((flags_w + 2)); }

    tab_width+=("$((5 + ${#idx} + ${#name} + flags_w))")

    is_active="#{?#{==:${idx},#{window_index}}"
    idx_style="${is_active},#[fg=${IDX_FG_A}#,bg=${IDX_BG_A}],#[fg=${IDX_FG_I}#,bg=${IDX_BG_I}]}"
    name_style="${is_active},#[fg=${NAME_FG_A}#,bg=${NAME_BG_A}],#[fg=${NAME_FG_I}#,bg=${NAME_BG_I}]}"

    tab_str+=("#[bg=${BG}] ${idx_style} ${idx} ${name_style} ${name} ${flags}")
done

# --- Collect unique window IDs from pane list ---
declare -A seen_windows
window_ids=()
for ((i = 0; i < total_panes; i++)); do
    wid="${pane_win_ids[$i]}"
    if [[ -z "${seen_windows[$wid]}" ]]; then
        seen_windows[$wid]=1
        window_ids+=("$wid")
    fi
done

# --- Batched set-option with auto-flush when command gets too large ---
cmd=(tmux)
cmd_bytes=4
first_cmd=true

flush_cmd() {
    if [[ ${#cmd[@]} -gt 1 ]]; then
        "${cmd[@]}"
        cmd=(tmux)
        cmd_bytes=4
        first_cmd=true
    fi
}

queue_set() {
    local pid="$1" value="$2"
    local entry_bytes=$((30 + ${#pid} + ${#value}))

    if [[ $((cmd_bytes + entry_bytes)) -gt $MAX_CMD_BYTES && ${#cmd[@]} -gt 1 ]]; then
        flush_cmd
    fi

    $first_cmd && first_cmd=false || cmd+=(";" )
    cmd+=(set-option -p -t "$pid" @pane_tabs "$value")
    cmd_bytes=$((cmd_bytes + entry_bytes))
}

# --- For each window, distribute tabs across its bottom panes ---
for wid in "${window_ids[@]}"; do
    bottom=()
    non_bottom=()
    for ((i = 0; i < total_panes; i++)); do
        [[ "${pane_win_ids[$i]}" != "$wid" ]] && continue
        if [[ "${pane_at_bottom[$i]}" == "1" ]]; then
            bottom+=("$i")
        else
            non_bottom+=("$i")
        fi
    done

    # Sort bottom panes by pane_left (insertion sort, small N)
    for ((i = 1; i < ${#bottom[@]}; i++)); do
        key=${bottom[$i]}
        j=$((i - 1))
        while [[ $j -ge 0 && ${pane_lefts[${bottom[$j]}]} -gt ${pane_lefts[$key]} ]]; do
            bottom[$((j + 1))]=${bottom[$j]}
            j=$((j - 1))
        done
        bottom[$((j + 1))]=$key
    done

    # Distribute tabs across this window's bottom panes
    tab_cursor=0
    for bi in "${bottom[@]}"; do
        remaining=$((pane_widths[bi] - BORDER_OVERHEAD))
        content=""

        while [[ $tab_cursor -lt $total_tabs ]]; do
            tw=${tab_width[$tab_cursor]}
            if [[ $tw -le $remaining ]]; then
                content+="${tab_str[$tab_cursor]}"
                remaining=$((remaining - tw))
                tab_cursor=$((tab_cursor + 1))
            else
                break
            fi
        done

        [[ -n "$content" ]] && content+="#[bg=${BG}]#[default]"
        queue_set "${pane_ids[$bi]}" "$content"
    done

    for ni in "${non_bottom[@]}"; do
        queue_set "${pane_ids[$ni]}" ""
    done
done

flush_cmd
