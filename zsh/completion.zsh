#Tab completion for ssh
hosts=(pi@192.168.16.136 ubuntu@drakirus.xyz)
zstyle ':completion:*:hosts'  hosts $hosts
