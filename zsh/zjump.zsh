autoload -Uz chpwd_recent_dirs cdr
autoload -U add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs

zstyle ':chpwd:*' recent-dirs-file ${ZDOTDIR:-$HOME}/.chpwd-recent-dirs
zstyle ':chpwd:*' recent-dirs-max 1024

# check for fzf installed
if ! [ $commands[fzf] ]; then
  echo "[zjump]: couldn't find fzf installation" >&2
  echo "[zjump]: please install fzf in order to use zjump" >&2
fi

function zjump {
  # check for fzf installed
  if ! [ $commands[fzf] ]; then
    echo "couldn't find fzf installation" >&2
    return 1
  fi

  local cmd="$1"
  case "$cmd" in
    '--help'|'-h') # print usage
      echo "usage: j [<query|command>]\n"
      echo "available commands:"
      echo "  -h, --help           print this help and exit"
      echo "  -p, --purge          remove all no exsiting directories from history"
      shift;
      ;;
    '--purge'|'-p') # remove all not existing directories from history
      local cdr_dir
      cdr -l | sed 's|^[^ ]* *||' \
          | while read cdr_dir; do
            if [[ ! -d ${~cdr_dir} ]]; then
              echo "remove ${cdr_dir}"
              # (b) - escape globbing ch
              cdr -P ${${(b)cdr_dir}/#'\~'/'~'}
            fi
          done
      shift;
      ;;

    '..') # parent directories selection
      shift;
      local dir_query=$@

      local dir_list=(${(s:/:)PWD%/*})
      dir_list=$(for dir_index in {0..$((${#dir_list}))}; echo /${(j:/:)dir_list:0:$dir_index})
      local dir # local declaration needs a seperate line to be able to catch fzf_status
      dir=$(echo ${dir_list}\
          | tr '\n' '\0' | xargs -0 ls -f  -d 2>/dev/null \
          | fzf --tac --height 10 --reverse --no-sort --query "$dir_query" -i --select-1)
      local fzf_status=$status
      if [[ $fzf_status != 0 ]]; then
        return $fzf_status
      fi

      builtin cd $dir
      ;;

    '.') # sub-directories selection
      shift;
      local dir_query=$@

      local dir # local declaration needs a seperate line to be able to catch fzf_status
      dir=$(find . -mindepth 1 -type d 2>&1 | sed 's/^\.\///' \
          | tr '\n' '\0' | xargs -0 ls -f  -d 2>/dev/null \
          | fzf --tac --height 10 --reverse --query "$dir_query" -i --select-1)
      local fzf_status=$status
      if [[ $fzf_status != 0 ]]; then
        return $fzf_status
      fi

      builtin cd $dir
      ;;

    *) # history directories selection
      local dir_query=$@
      local sed_escaped_HOME=$(echo $HOME | sed -e 's/[]\/$*.^[]/\\&/g')

      local dir # local declaration needs a seperate line to be able to catch fzf_status
      dir=$(cdr -l | sed 's/^[0-9]* *//g' | sed "s/^~/$sed_escaped_HOME/" \
          | tr '\n' '\0' | xargs -0 ls -f -d 2>/dev/null \
          | fzf --height 10 --reverse --query "$dir_query" -i --select-1)
      local fzf_status=$status
      if [[ $fzf_status != 0 ]]; then
        return $return_code
      fi

      builtin cd $dir
      ;;
  esac
}

compctl -U -K _no_completion zjump

alias j=zjump
