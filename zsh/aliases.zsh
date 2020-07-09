alias cls="clear && ls"
alias gs="gdstst"
alias gau="git add -u"
alias gpatch="git format-patch -1 HEAD"
alias git-size="git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '/^blob/ {print substr($0,6)}' | sort --numeric-sort --key=2 | cut --complement --characters=13-40 | numfmt --field=2 --to=iec-i --suffix=B --padding=7 --round=neares"
# alias e="thunar &> /dev/null &"
alias e="thunarCmd > /dev/null 2>&1"
alias x=extract  #Function extract
alias q="exit"
alias dc="docker-compose"
alias size="du -h --max-depth=1 . | sort -h"
alias http_serv="python3 -m http.server"
alias sshuttle="sshuttle --dns -vvr drakirus@drakirus.com 0/0"
alias paclean="sudo pacman -Rns \$(pacman -Qqtd)"

# NAS
alias backup-lab="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/lab /run/mount/NAS/xps13-Backup/"
alias backup-music="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/Musique /run/mount/NAS/xps13-Backup/"
alias backup-image="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/Images /run/mount/NAS/xps13-Backup/"
alias backup-resource="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/resource /run/mount/NAS/xps13-Backup/"
alias nas="sudo mkdir -p /run/mount/NAS; sudo mount -t nfs -rw 192.168.16.146:/volume1/Share /run/mount/NAS/"
alias unas="sudo umount -l /run/mount/NAS"

# drakirus.com
alias weeb_send="rsync -avPh --delete ~/Weeb/ drakirus@drakirus.com:APP/data/www/gif --rsh='ssh -p2242' "
alias resume_send="test -f ~/Downloads/resume.pdf && mv ~/Downloads/resume.pdf ~/lab/resume/resume.pdf; rsync -vPh ~/lab/resume/resume.pdf drakirus@drakirus.com:APP/data/www/resume --rsh='ssh -p2242'"

alias tri="exiftool -if '\$rating >= 1' -d './tri' '-directory<createdate' ."
alias bt="sudo systemctl start bluetooth.service"
alias neof="neofetch --memory_display barinfo"
alias grip="grip --pass afab9ab158c3a52283f9bf2adfc2b6a3fe6286b2 -b"
alias mv="mv -iv"
alias cp="cp -aiv"
alias py="python"
alias py2="python2"
alias docker_alpine="docker run -it --rm alpine /bin/ash"
alias music="mpv ./* --shuffle --no-video"
alias df="df --exclude-type=tmpfs -h"
alias de="adb devices"
alias de-screen="adb exec-out screencap -p > screen.png"
alias de-screen1="adb exec-out screencap -p > screen1.png"
alias de-screen2="adb exec-out screencap -p > screen2.png"
alias rm='trash'
alias loc='tokei'
function ln-broken(){find . -type l -exec sh -c 'file -b "$1" | grep -q ^broken' sh {} \; -print}

# CVS svn
alias sg="colorsvn status"
alias sc="colorsvn commit"
alias sl="colorsvn update"

alias ju="LC_ALL=en_US.UTF-8 jupyter notebook"

alias goo="google-chrome"

alias t="cd /tmp"
alias tl="cd ~/Downloads"

alias ms="LC_ALL=en_US.UTF-8 minishift"

alias tb="netcat termbin.com 9999 | xclip -selection c"

alias ncdusys="sudo ncdu / --exclude \"/home/*\" --color dark -rr -x --exclude .git --exclude node_modules"
alias ncdu="ncdu --color dark -rr -x --exclude .git --exclude node_modules"

# ssh
alias drak="ssh drakirus@drakirus.com -p 2242"
alias atal="env TERM=tmux-256color ssh s142293@transit.univ-lemans.fr"
alias webai="ssh dialog@172.16.250.7"
alias g5k-all="env TERM=tmux-256color ssh -t pchampion@access.grid5000.fr ssh -t nancy "
alias g5k="env TERM=tmux-256color ssh pchampion@access.nancy.grid5000.fr"
alias lst="ssh pchampi@lst1"


# cat ~/.ssh/id_rsa | ssh-key-on-line
alias ssh-key-on-line="openssl base64 | tr -d '\n'"
# echo $ONE-LINE-KEY | ssh-key-on-line-decode
alias ssh-key-on-line-decode="openssl base64 -A -d"

# alias cat="bat --theme=GitHub"
alias ping='prettyping --nolegend'

alias osc52clean='echo -e "\033]52;c;!\a"'
alias osc52='echo -e "\033]52;c;$(base64 <<< hello)\a"'

alias inria-screen-clean="inria-screen-all; sleep 4; inria-screen-one"

alias sig="cat resources/sig | xsel -b --clipboard"

alias ssh="env TERM=tmux-256color ssh"

# lychee photos
alias lychee_copy="scp -P 2242 -r ./*  drakirus@drakirus.com:~/APP/data/lychee_upload/import/drakirus"
alias lychee_import="ssh -t drakirus@drakirus.com -p 2242 'cd APP && make lychee-import'"
alias lychee_clean="ssh -t drakirus@drakirus.com -p 2242 'cd APP && cd data/lychee_upload/import/drakirus && rm * -rfv || cd - && docker-compose exec lychee php artisan lychee:ghostbuster 0 0'"

############
#  Editor  #
############

export EDITOR='nvim'
alias vim="nvim"
if [ -n "${NVIM_LISTEN_ADDRESS+x}" ]; then
  alias vim="nvimux-vim"
  export EDITOR='nvr'
fi
