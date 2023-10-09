############
#  Grid5K  #
############

# Reserving resources OAR Stuff + some alias
# Optimal Allocation of Resources (or Olivier Auguste Richard)

# JOB reservation through ORA
# this function takes 1 arg, the amount walltime of the job.
# The job submission will ask for 3 time this amount.
# And scale back to time passed in the arg.
# This allows to extant the walltime of job, which is not allowed on the
# g5k/nancy/production clusters.
#
# call this function through oar-xxx to select the CLUSTER.
_my-oar(){
    local cluster
    cluster=$CLUSTER
    gpu="$GPU"
    walltime=$1
    shift 1
    echo "oarsub -q production -p \"cluster='$cluster'\" -l ${gpu}walltime="$walltime":40 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 10d'"
    jobid=$(oarsub -q production -p "cluster='$cluster'" -l ${gpu}walltime="$walltime":40 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 10d' $@ | sed -n 's/OAR_JOB_ID=\(.*\)/\1/p')
    if [[ "$@" != "" ]]; then # in case of reservations (-r)
        return
    fi
    echo "Waiting for this job to be ready!"
    tput sc
    while [ $(oarstat -u | grep "$jobid" | awk '{print $5}') != "R" ]; do
        output=$(oarstat -u | grep "$jobid")
        tput rc; tput el
        echo $output
        oarstat -j "$jobid" --full | grep scheduledStart
        sleep 5
    done
    tput rc; tput ed;
    oarwalltime $jobid
}

function oar-1080(){
    CLUSTER='grele'
    _my-oar $@
}
function oar-2080(){
    CLUSTER='graffiti'
    _my-oar $@
}
function oar-t4(){
    CLUSTER='grue'
    _my-oar $@
}

function oar-grappe(){
    CLUSTER='grappe'
    _my-oar $@
}

function oar-grvingt(){
    CLUSTER='grvingt'
    _my-oar $@
}

alias oarwatch="watch -n 1 oarstat -u"

# activate conda venv
# Works on both g5k and laptop

function conda-so-activate(){
    if [[ $(hostname) == "xps-13" ]]; then
        source ~/lab/python/espnet/tools/venv/etc/profile.d/conda.sh
    else
        source ~/lab/espnet/tools/venv/etc/profile.d/conda.sh
    fi
    conda activate;
}

# Predefined drawgantt filters
#   Only show the GPU I'm interested into using
#   Print last hour of jobs and 24 hour ahead

function gg5k(){
    firefox --new-tab "https://intranet.grid5000.fr/oar/Nancy/drawgantt-svg-prod/drawgantt-svg.php?width=1400&filter=comment%20NOT%20LIKE%20%27Retired%20since%%27%20AND%20gpu%20%3E%200%20AND%20type=%27default%27%20and%20production=%27YES%27AND%20cluster!=%27graphite%27%20&timezone=Europe/Paris&resource_base=host&scale=10&config=prod&scale=20&width=1400&start=$(date +%s  --date='-2 hour')&stop=$(date +%s  --date='+55 hour')&resource_base=gpu"
}

# completion zsh

# see my-fzf-completion() in zsh/completion.zsh
_fzf-compl-oar(){
    fzf="$(__fzfcmd_complete)"
    preview='oarstat -j $(echo {}) -p | oarprint core -P host,gpu_model,gpu_count,cputype,memnode -F "$(tput bold) %$(tput sgr0) -| GPU=\"%\"x% CPU=\"%\" MEM=%MB |-" -f -'
    matches=$(command oarstat -u | \
            FZF_DEFAULT_OPTS=" --header-lines=2 --min-height 15 --reverse --preview '$preview' --preview-window top:1:wrap $FZF_DEFAULT_OPTS" ${=fzf} -m | \
        awk '{print $1}' | tr '\n' ' ')
    if [ -n "$matches" ]; then
        LBUFFER="$LBUFFER$matches"
    fi
}

# On a cluster's node,
# display the remaining walltime of this job
# if [[ -v OAR_JOBID  ]]; then
# startTimeJob=$(ssh $USER@fnancy "oarstat -j $OAR_JOBID -J | jq '.\"$OAR_JOBID\".\"startTime\"'")
# startTimeJob=$(date '+%Y-%m-%d %H:%M:%S' -d @$startTimeJob)
# walltime=$(ssh $USER@fnancy "oarwalltime $OAR_JOBID | sed -n 's/Current\swalltime:\s*\(.*\)/\1/p'")
# walltimeHour=$(echo $walltime | cut -d':' -f1 | awk '{print $1}')
# endTime=$(date '+%Y-%m-%d %H:%M:%S' -d "$startTimeJob +$walltimeHour hours")
# RPROMPT='${endTime}'
# fi
