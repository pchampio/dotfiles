# The login shell is bash, and ~/.profile execs zsh: SHELL stays /bin/bash.
# Programs that start "your shell" read SHELL. Claude Code with SHELL=/bin/bash
# cannot make its zsh snapshot and its background commands hang.
[[ $SHELL == */zsh ]] || export SHELL=${commands[zsh]:-$SHELL}

# Save a ton of history
HISTSIZE=1000000
HISTFILE=~/.zsh_history
SAVEHIST=1000000

# Disable % eof
unsetopt prompt_cr prompt_sp

eval `dircolors ~/dotfiles/config/dircolors/solarized.dir_colors`

# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Disable flow control commands (keeps C-s from freezing everything)
stty start undef
stty stop undef

setopt extendedglob

bindkey 'K' up-line-or-beginning-search
bindkey 'J' down-line-or-beginning-search

bindkey '^B' backward-word
bindkey '^G' forward-word

bindkey '^[w' kill-word

zstyle ':zle:*' word-context \ 
zstyle ':zle:transpose-words:whitespace' word-style shell
zstyle ':zle:transpose-words:filename' word-style normal
zstyle ':zle:transpose-words:filename' word-chars ''

# Show contents of directory after cd-ing into it
chpwd() {
  ls
}

# OSC 133, which is a control sequence that specifies where the prompt ended, and where the output of the executed program starts and ends.
_prompt_executing=""
_prompt_cmd_count=0
_prompt_lookup_max=0

_prompt_generate_lookup_fmt() {
    local n=$1
    local cur='#{e|+|:#{e|-|:#{history_size},#{scroll_position}},#{copy_cursor_y}}'
    local result="0"
    for ((i=1; i<=n; i++)); do
        result="#{?#{&&:#{@prompt_line_$i},#{e|<=|:#{@prompt_line_$i},$cur}},$i,$result}"
    done
    echo "$result"
}

function __prompt_precmd() {
    local ret="$status"
    if test "$_prompt_executing" != "0"
    then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if test "$_prompt_executing" != ""
    then
       printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    # No command runs: the terminal (WezTerm Rex) routes Ctrl-h/j/k/l to panes.
    # (WEZTERM_PICKER too, in case an fzf of a key binding was killed.)
    [[ -z "$TMUX" ]] && printf "\033]1337;SetUserVar=WEZTERM_PROG=\007\033]1337;SetUserVar=WEZTERM_PICKER=\007"
    _prompt_executing=0

    if [[ -n "$TMUX" ]]; then
        (( _prompt_cmd_count++ ))
        local line
        line=$(tmux display-message -p '#{e|+|:#{e|+|:#{history_size},#{cursor_y}},1}' 2>/dev/null)
        if [[ -n "$line" ]]; then
            tmux set -p "@prompt_line_$_prompt_cmd_count" "$line" 2>/dev/null
            tmux set -p @prompt_total "$_prompt_cmd_count" 2>/dev/null
            if (( _prompt_cmd_count > _prompt_lookup_max )); then
                local new_max=$(( (_prompt_cmd_count / 50 + 1) * 50 ))
                tmux set -p @prompt_lookup_fmt "$(_prompt_generate_lookup_fmt $new_max)" 2>/dev/null
                _prompt_lookup_max=$new_max
            fi
        fi
    fi
}
# fzf started by a key binding (Ctrl-R history, Ctrl-T) runs inside zsh's own
# process group, so the terminal cannot see it as the foreground program.
# While fzf runs, it sets the terminal variable WEZTERM_PICKER: WezTerm (Rex)
# then sends Ctrl-h/j/k/l to fzf instead of moving between panes. tmux finds
# fzf in the process tree instead (pscheck), so nothing is sent inside tmux.
function fzf() {
    local arg
    for arg in "$@"; do
        case $arg in --zsh|--bash|--fish|--version|--help|--man) command fzf "$@"; return ;; esac
    done
    if [[ -z "$TMUX" && ( -n "$REX_SESSION" || "$TERM_PROGRAM" == WezTerm ) ]] && { : >/dev/tty } 2>/dev/null; then
        printf '\033]1337;SetUserVar=WEZTERM_PICKER=%s\007' "$(printf fzf | base64)" >/dev/tty
        command fzf "$@"
        local code=$?
        printf '\033]1337;SetUserVar=WEZTERM_PICKER=\007' >/dev/tty
        return $code
    fi
    command fzf "$@"
}
function __prompt_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    # The running command line, also through SSH: the terminal sends Ctrl-j/k
    # to a picker (j/zjump runs fzf) instead of moving between panes.
    [[ -z "$TMUX" ]] && printf "\033]1337;SetUserVar=WEZTERM_PROG=%s\007" "$(printf '%s' "$1" | head -c 200 | base64 | tr -d '\n')"
    _prompt_executing=1
}
preexec_functions+=(__prompt_preexec)
precmd_functions+=(__prompt_precmd)

# Codex runs its sessions in a shared background server by default. That
# server has no terminal and no Rex variables: its hooks cannot report the
# agent status to WezTerm, and its commands cannot get their own Rex
# terminals. In a Rex session or in WezTerm, an interactive Codex keeps its
# session in its own process. CODEX_DAEMON=1 keeps the shared server.
function codex() {
    local -a subcommands=(exec e review login logout mcp mcp-server plugin app-server remote-control
                          completion update doctor sandbox debug apply a queue archive delete migrate-rollouts
                          agents cloud features help)
    if [[ -z "$CODEX_DAEMON" && ( -n "$REX_SESSION" || "$TERM_PROGRAM" == WezTerm ) ]] \
        && (( ! ${subcommands[(Ie)$1]} )) && (( ! ${@[(Ie)--remote]} )) && (( ! ${@[(Ie)--no-daemon]} )); then
        command codex --no-daemon "$@"
    else
        command codex "$@"
    fi
}

# TRAPINT to handle Ctrl-C with OSC 133 sequences
# Such that on incomplete (but with text) cmdline ctrl-c I still get the cmdline up/down navigation
_PROMPT_INTERRUPTED_BUFFER=""
function TRAPINT() {
    if [[ -n "${BUFFER//[[:space:]]/}" ]]; then
        _PROMPT_INTERRUPTED_BUFFER="$BUFFER"
        # Move to new line first, then OSC 133 sequences
        print
        printf "\033]133;C;\007"
        printf "\033]133;D;130;aid=%s\007" "$$"
        printf "\033]133;A;cl=m;aid=%s\007" "$$"
    fi
    return $(( 128 + $1 ))
}

# Widget to paste interrupted command
function _prompt_paste_interrupted() {
    if [[ -n "$_PROMPT_INTERRUPTED_BUFFER" ]]; then
        BUFFER="$_PROMPT_INTERRUPTED_BUFFER"
        CURSOR=${#BUFFER}
    fi
}
zle -N _prompt_paste_interrupted
bindkey '\e\C-k' _prompt_paste_interrupted
