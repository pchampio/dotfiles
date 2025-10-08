# Add to fpath if it exists
# Only prepend the custom zsh function dir if the system one doesn't exist
if [[ ! -d /usr/share/zsh/functions ]]; then
  ZSH_FUNC_DIR="$HOME/dotfiles/share/zsh/5.8/functions"
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

export EDITOR=$HOME/dotfiles/bin/nvim-linux-x86_64/bin/nvim

setopt prompt_subst # enable command substition in prompt

plugins=(encode64 docker sudo zsh-autoquoter)

# faster startup
DISABLE_AUTO_UPDATE="true"

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:$HOME/.local/podman/bin"

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

# perl
PATH=$PATH:/usr/bin/core_perl/


# local bin first
export PATH=$HOME/.local/share/pytool/bin:$HOME/.local/bin:$PATH

# ADD own dotfiles/bin app to Path
export PATH=$HOME/dotfiles/bin:$PATH

# Local lib (for pip usualy)
export LD_LIBRARY_PATH=/usr/local/lib/:"${LD_LIBRARY_PATH}"

# Ruby
ruby="/home/drakirus/.gem/ruby/2.6.0/bin"
PATH=$PATH:$ruby

# ADD perl path
export PATH=/usr/bin/vendor_perl:$PATH

# 10ms for key sequences
export KEYTIMEOUT=1

export PURE_PROMPT_SYMBOL="\$~"
zstyle :prompt:pure:prompt:success color green

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --follow --glob "!{.git,.svn,node_modules,bower_components}"'
export FZF_DEFAULT_OPTS='--bind ctrl-j:down,ctrl-k:up,alt-j:down,alt-k:up,tab:down,ctrl-z:toggle'

# Dart
export DART_SDK="/opt/flutter/bin/cache/dart-sdk/bin"
export PATH=${DART_SDK}:${PATH}

export PATH="$PATH":"$HOME/.pub-cache/bin"

# Flutter
export FLUTTER=/opt/flutter/bin
export PATH=${FLUTTER}:${PATH}

# Android - sdk
export ANDROID_HOME=/opt/android-sdk
export PATH=${PATH}:${JAVA_HOME}/bin:/opt/android-sdk/tools:/opt/android-sdk/platform-tools:/opt/android-sdk/tools/bin

# Rust
export PATH="$HOME/.cargo/bin:$PATH"

# tssh
export PATH="$HOME/dotfiles/bin/tssh:$PATH"
export PATH="$HOME/dotfiles/bin/tsshd:$PATH"
export PATH="$HOME/dotfiles/bin/trzsz:$PATH"

# watchman
export PATH="$HOME/dotfiles/bin/watchman_bin/:$PATH"
export LD_LIBRARY_PATH="$HOME/dotfiles/bin/watchman_bin/:${LD_LIBRARY_PATH}"

# tailscale
export PATH="$HOME/dotfiles/bin/tailscale:$PATH"

# Path for a single, persistent agent socket
export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"

# Check if the socket exists and points to a running agent
if ! [ -S "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
    # Kill any leftover agent using that socket
    if [ -S "$SSH_AUTH_SOCK" ]; then
        agent_pid=$(lsof -t "$SSH_AUTH_SOCK" 2>/dev/null)
        [ "$agent_pid" ] && kill "$agent_pid"
    fi
    # Start a new agent
    eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)" > /dev/null
fi

# Automatic fallback to Junest for not found commands in the native Linux system
# function command_not_found_handler(){
#     junest -f -- $@ || echo "Command not found:" + $1
# }

# source all .zsh files inside of the zsh/ directory
for config ($HOME/dotfiles/zsh/*.zsh) source $config

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=250"

# pipx
export PATH="$PATH:~/.local/bin"

# Atuin shell history
. "$HOME/.atuin/bin/env"
atuin-setup

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
export GOPATH=/home/prr/lab/go
export PATH=$GOPATH/bin:$PATH
