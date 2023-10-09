typeset -A abbrevs
abbrevs=(
    "lychee_rsync" "rsync -avzh --protect-args --progress -e 'ssh -p 2242' ./__CURSOR__ \"drakirus@drakirus.com:/home/drakirus/APP/data_s3fs/shared/photos/\" -n"
    "lychee_scp" "scp -P 2242 -r ./*  drakirus@drakirus.com:~/APP/data_s3fs/shared/photos/'"
    "awkd" "awk '{a[\$0]++}END{for(i in a){print i, a[i]}}'"
)

#create aliases for the abbrevs too
for abbr in ${(k)abbrevs}; do
    alias -g $abbr="${abbrevs[$abbr]}"
done

zle     -N   my-expand-abbrev
bindkey " " my-expand-abbrev

my-expand-abbrev() {
    local MATCH
    LBUFFER=${LBUFFER%%(#m)[_a-zA-Z0-9]#}
    command=${abbrevs[$MATCH]}
    LBUFFER+=${command:-$MATCH}

    if [[ "${command}" =~ "__CURSOR__" ]]; then
        RBUFFER=${LBUFFER[(ws:__CURSOR__:)2]}
        LBUFFER=${LBUFFER[(ws:__CURSOR__:)1]}
    else
        zle self-insert
    fi
}
