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
