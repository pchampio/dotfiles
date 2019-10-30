############
#  Grid5K  #
############

# Reserving resources
# Optimal Allocation of Resources (or Olivier Auguste Richard)
alias oar-1080="oarsub -p cluster='grele' -q production -l gpu=1/core=1,walltime=24  sleep 24h"
alias oar-2080="oarsub -p cluster='graffiti' -q production -l gpu=1/core=1,walltime=24  sleep 24h"

function conda-so-activate(){ source ~/lab/conda/etc/profile.d/conda.sh; conda activate;}

# wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
# chmod +x Miniconda3-latest-Linux-x86_64.sh
# bash Miniconda2-latest-Linux-x86_64.sh
# // Home to ~/lab/conda
# conda install cudnn
