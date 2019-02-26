
# Copied from https://github.com/nicknisi/dotfiles/blob/master/zsh/prompt.zsh

# heavily inspired by the wonderful pure theme
# https://github.com/sindresorhus/pure

# needed to get things like current git branch
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn # You can add hg too if needed: `git hg`
zstyle ':vcs_info:git*' use-simple true
zstyle ':vcs_info:git*' max-exports 2
zstyle ':vcs_info:git*' formats ' %b' 'x%R'
zstyle ':vcs_info:git*' actionformats ' %b|%a' 'x%R'

autoload colors && colors

git_dirty() {
  # check if we're in a git repo
  command git rev-parse --is-inside-work-tree &>/dev/null || return

  # check if it's dirty
  command git diff --quiet --ignore-submodules HEAD &>/dev/null;
  if [[ $? -eq 1 ]]; then
    echo "%F{red}✗%f"
  else
    echo "%F{green}✔%f"
  fi
}

svn_dirty() {
  # check if we're in a svn repo
 command svn info &>/dev/null || return

 result=`svn status -q`
 if [[ -z "$result" ]];then
   echo "%F{green}✔%f"
 else
   echo "%F{red}✗%f"
 fi
}

# get the status of the current branch and it's remote
# If there are changes upstream, display a ⇣
# If there are changes that have been committed but not yet pushed, display a ⇡
git_arrows() {
  # do nothing if there is no upstream configured
  command git rev-parse --abbrev-ref @'{u}' &>/dev/null || return

  local arrows=""
  arrow_status="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"

  # do nothing if the command failed
  (( !$? )) || return

  # split on tabs
  arrow_status=(${(ps:\t:)arrow_status})
  local left=${arrow_status[1]} right=${arrow_status[2]}

  (( ${left:-0} > 0 )) && arrows+="%F{012}⇡%f"
  (( ${right:-0} > 0 )) && arrows+="%F{011}⇣%f"

  # if no git fetch has been done
  # check on remote depo the commit hash
  if  [[  ! ${right:-0} > 0 &&  $# -ne 0 ]]; then

    # check if user use http and the repo is not private
    local remote_url=$(git config --get remote.origin.url)
    if [[ "$remote_url" =~ "http" ]]; then
      STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$remote_url")
      if [ $STATUS -ne 200 ]; then
        echo $arrows
        return
      fi
    fi

    # get remote_commit
    local remote_commit=$(git ls-remote -q --exit-code $(git rev-parse --abbrev-ref @{u} | \
      sed 's/\// /g') 2> /dev/null || echo $arrows && return )
    local remote_commit=$(echo $remote_commit | cut -f1)

    # get last local commit
    local local_commit=$(git rev-parse HEAD)
    if [[ "$remote_commit" = "$local_commit" ]]; then
      echo $arrows
      return
    fi

    # remote_commit is ancestor ? local_commit
    $(git merge-base --is-ancestor $remote_commit $local_commit 2>/dev/null )
    # echo $ancestor $local_commit $remote_commit
    if [[ $? -ne 0 ]]; then
      arrows+="%F{011}⇣%f"
    fi
  fi
  echo $arrows
}

# Displays the exec time of the last command if set threshold was exceeded
#
cmd_exec_time() {
  local stop=`date +%s`
  local start=${cmd_timestamp:-$stop}
  let local elapsed=$stop-$start

  local human=" "
  local days=$(( elapsed / 60 / 60 / 24 ))
  local hours=$(( elapsed / 60 / 60 % 24 ))
  local minutes=$(( elapsed / 60 % 60 ))
  local seconds=$(( elapsed % 60 ))
  (( days > 0 )) && human+="${days}d "
  (( hours > 0 )) && human+="${hours}h "
  (( minutes > 0 )) && human+="${minutes}m "
  human+="${seconds}s"
  [ $elapsed -gt 5 ] && echo ${human}

}

# Get the intial timestamp for cmd_exec_time
preexec() {
  cmd_timestamp=`date +%s`
}

# indicate a job (for example, vim) has been backgrounded
# If there is a job in the background, display a ✱
suspended_jobs() {
  local sj
  sj=$(jobs 2>/dev/null | tail -n 1)
  if [[ $sj == "" ]]; then
    echo ""
  else
    echo "%{$FG[208]%}✱%f "`jobs | cut --d=" " --f=5- | sed -r 's/^\s*//' | cut --d=" " --f=1 | tr '\n' ' '`
  fi
}

# Right-hand prompt
function RightPromptFunc() {

  vcsInfo=$( printf "%s\n" "$vcs_info_msg_0_" | sed 's/%20/ /g' | awk 'length > 25{$0=substr($0,0,22)"..."}1')
  echo `git_dirty``svn_dirty`%F{241}$vcsInfo%f `git_arrows``suspended_jobs`
}

# Right-hand prompt
function RightPromptFuncArrowsPull() {

  vcsInfo=$( printf "%s\n" "$vcs_info_msg_0_" | sed 's/%20/ /g' | awk 'length > 25{$0=substr($0,0,22)"..."}1' )
  echo `git_dirty``svn_dirty`%F{241}$vcsInfo%f `git_arrows 1``suspended_jobs`
}

ASYNC_PROC=0
precmd() {
  vcs_info

  # show username@host if logged in through SSH
  [[ "$SSH_CONNECTION" != ''  ]] && IPA=$(wget -qO- http://ipecho.net/plain &)
  [[ "$SSH_CONNECTION" != ''  ]] && prompt_username=" %F{242}%n@$IPA%f"
  print -P '\n%F{blue}%~$prompt_username%F{yellow}$(cmd_exec_time)%f'

  # remove the cmd_timestamp, indicating that precmd has completed
  unset cmd_timestamp

  function async() {
    # save to temp file
    printf "%s" "$(RightPromptFunc)" > "${HOME}/.zsh_tmp_prompt"

    # signal parent
    kill -s USR1 $$

    # save to temp file
    printf "%s" "$(RightPromptFuncArrowsPull)" > "${HOME}/.zsh_tmp_prompt"

    # signal parent
    kill -s USR1 $$
  }

  # do not clear RPROMPT, let it persist

  # kill child if necessary
  if [[ "${ASYNC_PROC}" != 0 ]]; then
    kill -s HUP $ASYNC_PROC >/dev/null 2>&1 || :
  fi

  # start background computation
  # async &!
  # ASYNC_PROC=$!

}

function TRAPUSR1() {
  # read from temp file
	RPROMPT="$(<${HOME}/.zsh_tmp_prompt)"

  # reset proc number
  ASYNC_PROC=0

  # redisplay
  zle && zle reset-prompt
}


# TRAPWINCH (){
# clear
# zle && zle reset-prompt
# }
