# Add to fpath if it exists
# Only prepend the custom zsh function dir if the system one doesn't exist
if [[ ! -d /usr/share/zsh/functions ]]; then
  ZSH_FUNC_DIR="$HOME/.local/share/zsh/5.8/functions"
  [[ -d "$ZSH_FUNC_DIR" ]] && fpath=("$ZSH_FUNC_DIR" $fpath)
fi

# Profiling zsh startup time
# time  zsh -i -c exit
profiling=false
if [ $profiling = true ]; then
  ## Per-command profiling:
  zmodload zsh/datetime
  setopt promptsubst
  PS4='+$EPOCHREALTIME %N:%i> '
  exec 3>&2 2> startlog.$$
  setopt xtrace prompt_subst
  ## Per-function profiling:
  zmodload zsh/zprof
fi

source $HOME/.config/instant-zsh.zsh
instant-zsh-pre "%004F${${(V)${(%):-%~}//\%/%%}//\///}%b%f"$'\n'"%002F\$~%f "

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# User configuration
export PATH="$HOME/.local/share/nvim/mason/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.local/podman/bin"

export EDITOR=$HOME/.local/bin/nvim

setopt prompt_subst # enable command substition in prompt

plugins=(encode64 docker sudo zsh-autoquoter)

# faster startup
DISABLE_AUTO_UPDATE="true"


export MANPATH="/usr/local/man:$MANPATH"

# fix: compaudit: 142 unknown group
ZSH_DISABLE_COMPFIX="true"
# add oh-my-zsh to zsh
source $ZSH/oh-my-zsh.sh
source $ZSH/syntax_highlighting/zsh-syntax-highlighting.zsh
source $ZSH/zsh-autosuggestions/zsh-autosuggestions.zsh

source $ZSH/custom/plugins/zsh-autoquoter/zsh-autoquoter.zsh
ZAQ_PREFIXES=('git commit( [^ ]##)# -[^ -]#m')
ZSH_HIGHLIGHT_HIGHLIGHTERS+=(zaq)

export BROWSER=/bin/firefox

# local bin first
export PATH=$HOME/.local/share/pytool/bin:$HOME/.local/bin:$PATH

# ADD own dotfiles/bin app to PATH
export PATH=$HOME/dotfiles/bin:$PATH

# Local lib (for pip usualy)
export LD_LIBRARY_PATH=/usr/local/lib/:"${LD_LIBRARY_PATH}"

# ADD perl path
export PATH=/usr/bin/vendor_perl:$PATH

# 10ms for key sequences
export KEYTIMEOUT=1

export PURE_PROMPT_SYMBOL="\$~"
zstyle :prompt:pure:prompt:success color green

hash fzf && source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='rg --files --follow --glob "!{.git,.svn,node_modules,bower_components}"'
export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up,alt-j:down,alt-k:up,tab:down,ctrl-z:toggle'

# Dart
export DART_SDK="/opt/flutter/bin/cache/dart-sdk/bin"
export PATH=${DART_SDK}:${PATH}

export PATH="$PATH":"$HOME/.pub-cache/bin"

# Flutter
export FLUTTER=/opt/flutter/bin
export PATH=${FLUTTER}:${PATH}

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

if ! pgrep -u $USER ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ ! -f ~/.ssh-agent-thing ]]; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
    eval $(<~/.ssh-agent-thing) > /dev/null
fi

# source all .zsh files inside of the zsh/ directory
for config ($HOME/dotfiles/zsh/*.zsh) source $config

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=250"

# Atuin shell history
atuin-setup

# OpenCode CLI
export PATH=$HOME/.opencode/bin:$PATH

instant-zsh-post

if [ $profiling = true ]; then
  ## Per-command profiling: (open startlog.*)
  unsetopt xtrace
  exec 2>&3 3>&-
  ## Per-function profiling:
  zprof
fi

# GoLang
# INSTALL go
# wget -q -O - https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash
export GOROOT=/opt/go
export PATH=$GOROOT/bin:$PATH
export GOPATH=$HOME/lab/go
export PATH=$GOPATH/bin:$PATH

# Android - sdk (over junest java)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/lab/commandlinetools-linux-13114758_latest/cmdline-tools/

export PATH="${JAVA_HOME}/bin:$PATH"
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$ANDROID_HOME/bin:$PATH"
