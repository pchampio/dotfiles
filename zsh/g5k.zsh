############
#  Grid5K  #
############

# Reserving resources
# Optimal Allocation of Resources (or Olivier Auguste Richard)
alias oar-1080="oarsub -q production -p \"cluster='grele'\" -l gpu=1/core=1,walltime=24 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 24h'"
alias oar-2080="oarsub -q production -p \"cluster='graffiti'\" -l gpu=1/core=1,walltime=24 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 24h'"

# completion zsh

function conda-so-activate(){ source ~/lab/conda/etc/profile.d/conda.sh; conda activate;}

function gg5k(){
  firefox --new-tab "https://intranet.grid5000.fr/oar/Nancy/drawgantt-svg-prod/drawgantt-svg.php?width=1400&filter=comment%20NOT%20LIKE%20%27Retired%20since%%27%20AND%20gpu%20%3E%200%20AND%20type=%27default%27%20and%20production=%27YES%27&timezone=Europe/Paris&resource_base=host&scale=10&config=prod&scale=20&width=1400&start=$(date +%s  --date='-5 hour')&stop=$(date +%s  --date='+12 hour')"
}

# wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
# chmod +x Miniconda3-latest-Linux-x86_64.sh
# bash Miniconda2-latest-Linux-x86_64.sh
# // Home to ~/lab/conda
# conda install cudnn

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
