############
#  Grid5K  #
############

# Reserving resources
# Optimal Allocation of Resources (or Olivier Auguste Richard)
alias oar-1080="oarsub -q production -p \"cluster='grele'\" -l walltime=5:59 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 6h'"
alias oar-2080="oarsub -q production -p \"cluster='graffiti'\" -l walltime=5:59 --stderr=$HOME/.cache/oar/%jobid%-err.log --stdout=$HOME/.cache/oar/%jobid%-out.log 'sleep 6h'"

alias oarWatch="watch -n 1 oarstat -u"

# completion zsh

function conda-so-activate(){ source ~/lab/espnet/tools/venv/etc/profile.d/conda.sh; conda activate;}

# wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
# chmod +x Miniconda3-latest-Linux-x86_64.sh
# bash Miniconda2-latest-Linux-x86_64.sh
# // Home to ~/lab/conda
# conda install cudnn

# == Espnet ==
# CUDAROOT = ~/lab/conda/pkgs/cudnn-7.6.0-cuda10.1_0/lib

# export PREFIX=$HOME/lab/conda; export CFLAGS="-I$PREFIX/include"; export LDFLAGS="-L$PREFIX/lib"; export CPATH=${PREFIX}/include; export PATH="$PATH:$HOME/lab/conda/bin/"
# tools/ make
# src/ ./configure --shared --openblas-root=$HOME/lab/conda --fst-root=$HOME/lab/conda --fst-version=1.6.1 --speex-root=$HOME/lab/conda --use-cuda=no
# src/ make -j clean depend; make -j $(nproc)

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
