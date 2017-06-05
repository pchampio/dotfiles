# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

setopt prompt_subst # enable command substition in prompt

export DOTFILES=$HOME/dotfiles
# source all .zsh files inside of the zsh/ directory
for config ($DOTFILES/**/*.zsh) source $config

export EDITOR='vim'

# faster startup
DISABLE_AUTO_UPDATE="true"

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/home/drakirus/.gem/ruby/2.3.0/bin:/home/drakirus/.gem/ruby/2.4.0/bin:$GOPATH/bin"

export MANPATH="/usr/local/man:$MANPATH"

# add oh-my-zsh to zsh
source $ZSH/oh-my-zsh.sh
source $ZSH/syntax_highlighting/zsh-syntax-highlighting.zsh
# source $ZSH/custom/fast-syntax-highlighting.plugin.zsh
# source $ZSH/custom/plugins/zsh-completions/zsh-completions.plugin.zsh

# Show contents of directory after cd-ing into it
chpwd() {
  ls
  if [ -f ./venv/bin/activate ]; then
    source ./venv/bin/activate
  fi
}

# GO config
# mkdir -p ~/lab/go/{pkg,src,bin}
export GOPATH=$HOME/lab/go
PATH=$PATH:$GOPATH/bin

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
export RPROMPT='' # set asynchronously and dynamically

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up'
# export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
# Android studio
export ANDROID_HOME=~/Android/Sdk
export PATH=${PATH}:${ANDROID_HOME}/tools

if ! pgrep -u $USER ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
    eval $(<~/.ssh-agent-thing)
fi
if [[ "$SSH_CONNECTION" == ''  ]]; then
  SessionNb=$( tmux list-sessions -F "#S" 2>/dev/null | wc -l )
  if [ $SessionNb -eq 0 ]; then
    tm && exit
  fi
fi
