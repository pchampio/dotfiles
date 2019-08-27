# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

setopt prompt_subst # enable command substition in prompt

plugins=(encode64 docker sudo)

# faster startup
DISABLE_AUTO_UPDATE="true"

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/home/drakirus/.gem/ruby/2.3.0/bin:/home/drakirus/.gem/ruby/2.4.0/bin:$GOPATH/bin:/home/drakirus/.gem/ruby/2.5.0/bin:/opt/miniconda3/bin/"

export MANPATH="/usr/local/man:$MANPATH"

# add oh-my-zsh to zsh
source $ZSH/oh-my-zsh.sh
source $ZSH/syntax_highlighting/zsh-syntax-highlighting.zsh
source $ZSH/zsh-autosuggestions/zsh-autosuggestions.zsh

export BROWSER=/bin/firefox

# Show contents of directory after cd-ing into it
chpwd() {
  ls
  if [ -f ./venv/bin/activate ]; then
    source ./venv/bin/activate
  fi
}

# mw
PATH=$PATH:$HOME/dotfiles/mutt-wizard/bin

# perl
PATH=$PATH:/usr/bin/core_perl/

# GO config
# mkdir -p ~/lab/go/{pkg,src,bin}
export GOPATH=$HOME/lab/go
PATH=$PATH:$GOPATH/bin

# pip path
PATH=$PATH:$HOME/.local/bin

# ADD own dotfiles/bin app to Path
export PATH=$HOME/dotfiles/bin:$PATH

# Add emacs bins
export PATH=$HOME/.emacs.d/bin:$PATH


# Local lib (for pip usualy)
export LD_LIBRARY_PATH=/usr/local/lib/:"${LD_LIBRARY_PATH}"

# Python
PYTHONPATH="/usr/local/lib/python3.7/site-packages/":"${PYTHONPATH}"
export PYTHONPATH

# Ruby
ruby="/home/drakirus/.gem/ruby/2.6.0/bin"
PATH=$PATH:$ruby

# ADD perl path
export PATH=/usr/bin/vendor_perl:$PATH

# 10ms for key sequences
export KEYTIMEOUT=1

# vim as a man-page viewer
export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
    nvim -R -c 'set ft=man nomod nolist' -c 'map q :q<CR>' \
    -c 'map <SPACE> <C-D>' -c 'map b <C-U>' \
    -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""


# if [[ -n "$TMUX" ]]; then
  # local LVL=$(($SHLVL - 3))
# else
  # local LVL=1
# fi

# local SUFFIX=$(printf '❯%.0s' {1..$LVL})

zstyle :prompt:pure:prompt:success color green

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --follow --glob "!{.git,.svn,node_modules,bower_components}"'
export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up'


# JAVA_HOME
# export JAVA_HOME=/usr/lib/jvm/jdk-9.0.1
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk

export AS_JAVA=/usr/lib/jvm/java-8-jdk

# Android - sdk
export ANDROID_HOME=/opt/android-sdk

export FLUTTER=/opt/flutter/bin

export PATH=${FLUTTER}:${JAVA_HOME}/bin:${PATH}:/opt/android-sdk/tools:/opt/android-sdk/platform-tools:/opt/android-sdk/tools/bin

export PATH="$PATH":"$HOME/.pub-cache/bin"

if ! pgrep -u $USER ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
    eval $(<~/.ssh-agent-thing)
fi

if [[ "$SSH_CONNECTION" == '' && "$FROM_IDEA" == ''  ]]; then
  SessionNb=$( tmux list-sessions -F "#S" 2>/dev/null | wc -l )
  if [ $SessionNb -eq 0 ]; then
    # tm && exit
  fi
fi

m() {
  if [ -z "$1" ]
  then
    emacsclient -e "(find-file-in-project \"`pwd`\")"
  else
    emacsclient -n "$@"
  fi
}


export DOTFILES=$HOME/dotfiles
# source all .zsh files inside of the zsh/ directory
for config ($DOTFILES/**/*.zsh) source $config

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=white"
