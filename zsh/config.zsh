# Save a ton of history
HISTSIZE=1000000
HISTFILE=~/.zsh_history
SAVEHIST=1000000

# Disable % eof
unsetopt prompt_cr prompt_sp

eval `dircolors ~/dotfiles/dircolors/solarized.dir_colors`

# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Enable completion
# autoload -Uz compinit
# compinit

# Disable flow control commands (keeps C-s from freezing everything)
stty start undef
stty stop undef

setopt extendedglob
# rm -- ^file.txt

bindkey 'K' up-line-or-beginning-search
bindkey 'J' down-line-or-beginning-search

bindkey '^B' backward-word
bindkey '^F' forward-word

bindkey '^[w' kill-word

zstyle ':zle:*' word-context \ 
zstyle ':zle:transpose-words:whitespace' word-style shell
zstyle ':zle:transpose-words:filename' word-style normal
zstyle ':zle:transpose-words:filename' word-chars ''

# OSC 133, which is a control sequence that specifies where the prompt ended, and where the output of the executed program starts and ends.
_prompt_executing=""
function __prompt_precmd() {
    local ret="$?"
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
    _prompt_executing=0
}
function __prompt_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    _prompt_executing=1
}
preexec_functions+=(__prompt_preexec)
precmd_functions+=(__prompt_precmd)
