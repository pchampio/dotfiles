[ -z "$fzf_default_completion" ] && {
  binding=$(bindkey '^I')
  [[ $binding =~ 'undefined-key' ]] || fzf_default_completion=$binding[(s: :w)2]
  unset binding
}

zle     -N   my-fzf-completion
bindkey '^I' my-fzf-completion

my-fzf-completion() {
    [ -z "$fzf_default_completion" ] && {
        binding=$(bindkey '^I')
        [[ $binding =~ 'undefined-key' ]] || fzf_default_completion=$binding[(s: :w)2]
        unset binding
    }

    tokens=(${(z)LBUFFER})
    if [ ${#tokens} -lt 1 ]; then
        zle ${fzf_default_completion:-expand-or-complete}
        return
    fi

    cmd=${tokens[1]}

    # trigger-less completion
    if [ $cmd = "oarsub" ]; then
        if [ ${LBUFFER[-1]} = ' ' -a ${LBUFFER[-2]} = 'C' ]; then
            _fzf-compl-oar
            zle reset-prompt
        fi
        return
    fi
    if [ $cmd = "oardel" ]; then
        _fzf-compl-oar
        zle reset-prompt
        return
    fi


    # Fall back to default completion
    zle ${fzf_default_completion:-expand-or-complete}

}

# example:
_fzf-compl-oar(){
    fzf=fzf
    preview='oarstat -j $(echo {}) -p | oarprint core -P host,gpu_model,gpu_count,cputype,memnode -F "$(tput bold) %$(tput sgr0) -| GPU=\"%\"x% CPU=\"%\" MEM=%MB |-" -f -'
    matches=$(command oarstat -u | \
            FZF_DEFAULT_OPTS=" --header-lines=2 --min-height 15 --reverse --preview '$preview' --preview-window top:1:wrap $FZF_DEFAULT_OPTS" ${=fzf} -m | \
        awk '{print $1}' | tr '\n' ' ')
    if [ -n "$matches" ]; then
        LBUFFER="$LBUFFER$matches"
    fi
}


# Search history
atuin-setup() {
  export ATUIN_NOBIND="true"
  eval "$(atuin init zsh)"
  ! hash atuin && return


  # Commands to ignore entirely (even with args)
  local ignore_full=(q less clear exit)

  # Commands to ignore only when used *alone*
  local ignore_alone=(vim nano nvim v ls la)

  # Build regex patterns
  pattern="^(${(j:|:)ignore_full})(\s|$)|^(${(j:|:)ignore_alone})$"


  fzf-atuin-history-widget() {
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null

    local atuin_opts="--cmd-only --print0 --limit ${ATUIN_LIMIT:-5000}"
    local fzf_opts=(
            --height=${FZF_TMUX_HEIGHT:-80%}
            --tac
            "-n2..,.."
            --tiebreak=index
            "--query=${LBUFFER}"
            "--read0"
            --prompt "History> "
            "+m"
            "--bind" "ctrl-r:transform:
            # Inspect current prompt and cycle to the next one
             # Add --exit 0 if prompt starts with Success
            exit_flag='--exit 0'
            pprompt=''
            if [[ \"\$FZF_PROMPT\" == Failed* ]]; then
                pprompt='Failed '
                FZF_PROMPT=\${FZF_PROMPT/Failed }
                exit_flag=''
            fi

            if [ \"\$FZF_PROMPT\" = 'History> ' ]; then
                printf \"reload(atuin search $atuin_opts \$exit_flag -c $PWD | grep -avzE '$pattern')+change-prompt(\${pprompt}History (pwd)> )\"
            elif [ \"\$FZF_PROMPT\" = 'History (pwd)> ' ]; then
                printf \"reload(ATUIN_SESSION=$ATUIN_SESSION atuin search $atuin_opts \$exit_flag --filter-mode session | grep -avzE '$pattern')+change-prompt(\${pprompt}History (session)> )\"
            elif [ \"\$FZF_PROMPT\" = 'History (session)> ' ]; then
                printf \"reload(atuin search $atuin_opts \$exit_flag --filter-mode host | grep -avzE '$pattern')+change-prompt(\${pprompt}History (host)> )\"
            else
                printf \"reload(atuin search $atuin_opts \$exit_flag | grep -avzE '$pattern')+change-prompt(\${pprompt}History> )\"
            fi
            "
            "--bind" "ctrl-y:transform:
            # Inspect current prompt and cycle to the next one
             # Add --exit 0 if prompt starts with Success
            exit_flag='--exit 0'
            pprompt=''
            if [[ \"\$FZF_PROMPT\" == Failed* ]]; then
                FZF_PROMPT=\${FZF_PROMPT/Failed }
            else
                pprompt='Failed '
                exit_flag=''
            fi

            if [ \"\$FZF_PROMPT\" = 'History> ' ]; then
                printf \"reload(atuin search $atuin_opts \$exit_flag | grep -avzE '$pattern')+change-prompt(\${pprompt}History> )\"
            elif [ \"\$FZF_PROMPT\" = 'History (pwd)> ' ]; then
                printf \"reload(atuin search $atuin_opts \$exit_flag -c $PWD | grep -avzE '$pattern')+change-prompt(\${pprompt}History (pwd)> )\"
            elif [ \"\$FZF_PROMPT\" = 'History (session)> ' ]; then
                printf \"reload(ATUIN_SESSION=$ATUIN_SESSION atuin search $atuin_opts \$exit_flag --filter-mode session | grep -avzE '$pattern')+change-prompt(\${pprompt}History (session)> )\"
            elif [ \"\$FZF_PROMPT\" = 'History (host)> ' ]; then
                printf \"reload(atuin search $atuin_opts \$exit_flag --filter-mode host | grep -avzE '$pattern')+change-prompt(\${pprompt}History (host)> )\"
            fi
            "
    )

    selected=$(
        eval "atuin search ${atuin_opts} --exit 0" | grep -avzE "$pattern" |
        fzf "${fzf_opts[@]}"
    )
    local ret=$?
    if [ -n "$selected" ]; then
        LBUFFER="${selected}"
    fi
    zle reset-prompt
    return $ret
  }
  zle -N fzf-atuin-history-widget
  bindkey '^R' fzf-atuin-history-widget
}

