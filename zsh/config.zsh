# Save a ton of history
HISTSIZE=20000
HISTFILE=~/.zsh_history
SAVEHIST=20000

# Enable completion
autoload -U compinit
compinit

# Disable flow control commands (keeps C-s from freezing everything)
stty start undef
stty stop undef


# change dir color
if [[ -e "$HOME/.vim/autoload/gruvbox/" ]]; then
  source "$HOME/.vim/autoload/gruvbox/gruvbox_256palette.sh"
  eval `dircolors ~/dotfiles/dircolors/gruvbox.dir_colors`
else
  eval `dircolors ~/dotfiles/dircolors/solarized.dir_colors`
fi

# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

