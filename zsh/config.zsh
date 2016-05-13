# Save a ton of history
HISTSIZE=20000000
HISTFILE=~/.zsh_history
SAVEHIST=20000000


[ -d ~/.vim/autoload/gruvbox ] && source ~/.vim/autoload/gruvbox/gruvbox_256palette.sh
eval `dircolors ~/dotfiles/dircolors/gruvbox.dir_colors`

# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Enable completion
autoload -Uz compinit
compinit

# Disable flow control commands (keeps C-s from freezing everything)
stty start undef
stty stop undef
