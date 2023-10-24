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
