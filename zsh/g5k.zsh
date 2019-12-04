############
#  Grid5K  #
############

# Reserving resources
# Optimal Allocation of Resources (or Olivier Auguste Richard)

# call this function through oar-xxx
_my-oar(){
  local cluster
  cluster=$CLUSTER
  walltime=$1
  shift 1
  jobid=$(oarsub -q production -p "cluster='$cluster'" -l walltime="$walltime":40 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 10d' $@ | sed -n 's/OAR_JOB_ID=\(.*\)/\1/p')
  if [[ "$@" != "" ]]; then # in case of reservations (-r)
    return
  fi
  echo "Waiting for this job to be ready!"
  tput sc
  while [ $(oarstat -u | grep "$jobid" | awk '{print $5}') != "R" ]; do
    output=$(oarstat -u | grep "$jobid")
    tput rc; tput el
    echo $output
    sleep 2
  done
  tput rc; tput ed;
  oarwalltime $jobid
  curl --silent -X POST "https://notif.drakirus.com/message?token=AVTzIYbFxGtl8aU" -F "title=Grid5k" -F "message=$cluster ready, jobid: $jobid" > /dev/null
}

function oar-1080(){
  CLUSTER='grele'
  _my-oar $@
}
function oar-2080(){
  CLUSTER='graffiti'
  _my-oar $@
}

alias oarwatch="watch -n 1 oarstat -u"

# completion zsh

function conda-so-activate(){ source ~/lab/espnet/tools/venv/etc/profile.d/conda.sh; conda activate;}

function gg5k(){
  firefox --new-tab "https://intranet.grid5000.fr/oar/Nancy/drawgantt-svg-prod/drawgantt-svg.php?width=1400&filter=comment%20NOT%20LIKE%20%27Retired%20since%%27%20AND%20gpu%20%3E%200%20AND%20type=%27default%27%20and%20production=%27YES%27AND%20cluster!=%27graphique%27%20AND%20cluster!=%27graphite%27%20&timezone=Europe/Paris&resource_base=host&scale=10&config=prod&scale=20&width=1400&start=$(date +%s  --date='-2 hour')&stop=$(date +%s  --date='+24 hour')"
}

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
if [[ -v OAR_JOBID  ]]; then
  # startTimeJob=$(ssh $USER@fnancy "oarstat -j $OAR_JOBID -J | jq '.\"$OAR_JOBID\".\"startTime\"'")
  # startTimeJob=$(date '+%Y-%m-%d %H:%M:%S' -d @$startTimeJob)
  # walltime=$(ssh $USER@fnancy "oarwalltime $OAR_JOBID | sed -n 's/Current\swalltime:\s*\(.*\)/\1/p'")
  # walltimeHour=$(echo $walltime | cut -d':' -f1 | awk '{print $1}')
  # endTime=$(date '+%Y-%m-%d %H:%M:%S' -d "$startTimeJob +$walltimeHour hours")
  # RPROMPT='${endTime}'
fi
