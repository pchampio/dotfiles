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

# change dir color https://github.com/seebi/dircolors-solarized#installation
eval `dircolors ~/dotfiles/dircolors`
# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
