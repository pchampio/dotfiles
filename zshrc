# Profiling zsh startup time
# time  zsh -i -c exit
profiling=false
if [ $profiling = true ]; then
  ## Per-command profiling:
  # zmodload zsh/datetime
  # setopt promptsubst
  # PS4='+$EPOCHREALTIME %N:%i> '
  # exec 3>&2 2> startlog.$$
  # setopt xtrace prompt_subst
  ## Per-function profiling:
  zmodload zsh/zprof
fi

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

setopt prompt_subst # enable command substition in prompt

plugins=(encode64 docker sudo zsh-autoquoter)

# faster startup
DISABLE_AUTO_UPDATE="true"

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"

export MANPATH="/usr/local/man:$MANPATH"

# add oh-my-zsh to zsh
source $ZSH/oh-my-zsh.sh
source $ZSH/syntax_highlighting/zsh-syntax-highlighting.zsh
source $ZSH/zsh-autosuggestions/zsh-autosuggestions.zsh

source $ZSH/custom/plugins/zsh-autoquoter/zsh-autoquoter.zsh
ZAQ_PREFIXES=('git commit( [^ ]##)# -[^ -]#m')
ZSH_HIGHLIGHT_HIGHLIGHTERS+=(zaq)

export BROWSER=/bin/firefox

# Show contents of directory after cd-ing into it
chpwd() {
  ls
  # if [ -f ./venv/bin/activate ]; then
    # source ./venv/bin/activate
  # fi
}

# downgrade command in manjaro
export DOWNGRADE_FROM_ALA=1

# mosh
export LD_LIBRARY_PATH=$HOME/dotfiles/bin/mosh/lib
PATH=$PATH:$HOME/dotfiles/bin/mosh/bin

# mw
PATH=$PATH:$HOME/dotfiles/mutt-wizard/bin

# perl
PATH=$PATH:/usr/bin/core_perl/

# GO config
# mkdir -p ~/lab/go/{pkg,src,bin}
export GOPATH=$HOME/lab/go
export GOROOT=/opt/go
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
# INSTALL go
# wget -q -O - https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash

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


export PURE_PROMPT_SYMBOL="\$~"
zstyle :prompt:pure:prompt:success color green

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --follow --glob "!{.git,.svn,node_modules,bower_components}"'
export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up,tab:down'

# Nix
if [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
  source ~/.nix-profile/etc/profile.d/nix.sh
fi

# Dart
export DART_SDK="/opt/flutter/bin/cache/dart-sdk/bin"
export PATH=${DART_SDK}:${PATH}

export PATH="$PATH":"$HOME/.pub-cache/bin"

# Flutter
export FLUTTER=/opt/flutter/bin
export PATH=${FLUTTER}:${PATH}

# JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk/jre

# Android - sdk
export ANDROID_HOME=/opt/android-sdk
export PATH=${PATH}:${JAVA_HOME}/bin:/opt/android-sdk/tools:/opt/android-sdk/platform-tools:/opt/android-sdk/tools/bin

if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  export TERM=screen-256color
fi

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# vim ~/.ssh/config #
# AddKeysToAgent yes
# ForwardAgent yes
if ! pgrep -u $USER ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
    eval $(<~/.ssh-agent-thing) > /dev/null
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

# source all .zsh files inside of the zsh/ directory
for config ($HOME/dotfiles/zsh/*.zsh) source $config

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=250"

if [ $profiling = true ]; then
  ## Per-command profiling: (open startlog.*)
  # unsetopt xtrace
  # exec 2>&3 3>&-
  ## Per-function profiling:
  zprof
fi
