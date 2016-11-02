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

# vim as a man-page viewer
export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    vim -R -c 'set ft=man nomod nolist' -c 'map q :q<CR>' \
    -c 'map <SPACE> <C-D>' -c 'map b <C-U>' \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""

# PROMPT THEME
export PROMPT='%(?.%F{green}.%F{red})❯%f '
export RPROMPT='`git_dirty`%F{241}$vcs_info_msg_0_%f `git_arrows``suspended_jobs`'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up'

# Android studio
export ANDROID_HOME=~/Android/Sdk
export PATH=${PATH}:${ANDROID_HOME}/tools
