# Set prompt string to show time left for srun
if [ ! -z $SLURM_JOB_ID ]; then
  PS1='(`squeue -hj $SLURM_JOB_ID -o "%L"` left) '$PS1
fi

###############
# SINFO aliases
###############
# Detailed sinfo
alias si="sinfo -o '%8P %10n %.11T %.4c %.8z %.6m %12G %10l %10L %10O %20E' -S '-P'"
# sinfo only on CPU partition
alias sic="sinfo -p cpu -o '%10n %.11T %.4c %.8z %.6m %10l %10L %10O %30E' -S 'T'"
# sinfo only on GPU partition
alias sig="sinfo -p gpu -o '%10n %.11T %.4c %.8z %.6m %12G %8f %10l %10L %10O %30E' -S 'T'"

################
# SQUEUE aliases
################
# Detailed squeue
alias sq="squeue -Su -o '%8i %10u %20j %4t %5D %20R %15b %3C %7m %10n %11l %11L'"
# squeue only on CPU partition
alias sqc="squeue -p cpu -Su -o '%8i %10u %20j %4t %5D %20R %3C %7m %10n %11l %11L'"
# squeue only your jobs
alias squ="sq -u `id -un`"
# squeue only on GPU partition
alias sqg="sq -p gpu"

#######################################################
# SSTAT alias to get information about your RUNNING job
# Usage: sst <jobid>
#     OR sst <jobid>.batch (if you use SBATCH and do
#                           not use SRUN inside)
#######################################################
alias sst='sstat -a --format=JobID,NTasks,AveCPU,AveRSS,MaxRSS,MaxDiskRead,MaxDiskWrite -j'

###############
# SACCT aliases
###############
# All jobs in last day
alias sac='sacct --units=G --format="JobId%15,JobName%20,NCPUS%4,NodeList,AllocGRES,ReqMem,MaxRSS,State,Elapsed"'
# Failed jobs in last day
alias sacf='sac -S 00:00:00 -s f,ca,to,nf,dl'
# Running jobs in last day
alias sacr='sac -s R'

#################
# SREPORT aliases
#################
alias sreu='sreport user top -t HourPer Format=Login%15,Used'

##########
# SCONTROL
##########
# scontrol show job -dd <jobid>
alias scj='scontrol show job -dd'
# writes batch script to a file for a running job
alias scwb='scontrol write batch_script'

alias gpus='gpusDispos.pl'
