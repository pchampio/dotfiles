# Path to your oh-my-zsh installation.  export ZSH=~/.oh-my-zsh
export ZSH=~/.oh-my-zsh
ZSH_THEME="pure"

plugins=(git)

# User configuration

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

export MANPATH="/usr/local/man:$MANPATH"

source $ZSH/oh-my-zsh.sh
source  ~/.oh-my-zsh/syntax_highlighting/zsh-syntax-highlighting.zsh

export PATH=$HOME/dotfiles/bin:$PATH

# aliases
alias cls="clear && ls"
alias gs="git status"
alias e="thunar &> /dev/null &"
alias tmux="TERM=screen-256color-bce tmux "
alias wemux='TERM=xterm-256color wemux'

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

# Show contents of directory after cd-ing into it
chpwd() {
  ls
}

# change dir color https://github.com/seebi/dircolors-solarized#installation
eval `dircolors ~/dotfiles/dircolors`
# colored completion - use my LS_COLORS
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

#Tab completion for ssh
hosts=(pi@192.168.16.136 ubuntu@52.36.243.11)
zstyle ':completion:*:hosts'  hosts $hosts
