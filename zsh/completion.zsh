[ -z "$fzf_default_completion" ] && {
    binding=$(bindkey '^I')
    [[ $binding =~ 'undefined-key' ]] || fzf_default_completion=$binding[(s: :w)2]
    unset binding
}

zle     -N   my-fzf-completion
bindkey '^I' my-fzf-completion

my-fzf-completion() {
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
    if [ $cmd = "oarwalltime" ]; then
        _fzf-compl-oar
        zle reset-prompt
        return
    fi


    # Fall back to default completion
    zle ${fzf_default_completion:-expand-or-complete}

}
