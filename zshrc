# Path to your oh-my-zsh installation.  export ZSH=~/.oh-my-zsh
export ZSH=~/.oh-my-zsh

export DOTFILES=$HOME/dotfiles
# source all .zsh files inside of the zsh/ directory
for config ($DOTFILES/**/*.zsh) source $config

export EDITOR='vim'

plugins=(git docker-enter)

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"

export MANPATH="/usr/local/man:$MANPATH"

# add oh-my-zsh to zsh
source $ZSH/oh-my-zsh.sh
source $ZSH/syntax_highlighting/zsh-syntax-highlighting.zsh

# Show contents of directory after cd-ing into it
chpwd() {
  ls
}

# ADD own dotfiles/bin app to Path
export PATH=$HOME/dotfiles/bin:$PATH

# 10ms for key sequences
export KEYTIMEOUT=1

# PROMPT THEME
export PROMPT='%(?.%F{green}.%F{red})❯%f '
export RPROMPT='`git_dirty`%F{241}$vcs_info_msg_0_%f `git_arrows``suspended_jobs`'
