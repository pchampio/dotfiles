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

            cdr -l | sed 's|^[^ ]* *||' | sed "s|^~|$HOME|" \
                | while read dir; do
                if [[ ! -d $dir ]]; then
                    echo "remove $dir"
                    cdr -P $dir
                fi
            done

            shift;
            ;;
        '..') # parent directories selection
            shift;
            local dir_query=$@

            local pwd_list=('/' '/'${^${(s:/:)PWD%/*}})
            local pwd_index
            pwd_index=$(echo ${(F)pwd_list} | nl \
                    | fzf --tac --height 10 --reverse --no-sort --query "$dir_query" --exact --select-1 --with-nth=2.. \
                | cut -f1)
                return_code=$status
                if [[ $return_code == 1 ]]; then
                    echo "no match" >&2
                    return 1
                elif [[ $return_code == 130 ]]; then
                    return 0
                fi

                local dir=${(j::)pwd_list:0:$pwd_index} # remove double
                builtin cd $dir
                ;;
            '.') # sub-directories selection
                shift;
                local dir_query=$@

                local dir
                dir=$(find . -mindepth 1 -type d 2>&1 \
                        | grep -v 'find:.*Permission denied' \
                        | sed 's|^\./\(.*\)|\1|' \
                    | fzf --tac --height 10 --reverse --query "$dir_query" --exact --select-1)
                    return_code=$status
                    if [[ $return_code == 1 ]]; then
                        echo "no match" >&2
                        return 1
                    elif [[ $return_code == 130 ]]; then
                        return 0
                    fi

                    builtin cd $dir
                    ;;
                *) # history directories selection
                    local dir_query=$@

                    local dir
                    dir=$( cdr -l | sed '/\/tmp/d'| sed 's|^[^ ]* *||' | sed 's|\\\(.\)|\1|g' \
                        | fzf --height 10 --reverse --query "$dir_query" --exact --select-1)

                        dir=$(echo $dir | sed "s|^~|$HOME|")
                        return_code=$status
                        if [[ $return_code == 1 ]]; then
                            echo "no match" >&2
                            return 1
                        elif [[ $return_code == 130 ]]; then
                            return 0
                        fi

                        builtin cd $dir
                        ;;
                esac
            }

            compctl -U -K _no_completion zjump

            alias j=zjump
