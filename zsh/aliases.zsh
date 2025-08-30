alias cls="clear && ls"
# alias e="thunar &> /dev/null &"
# alias e="thunarCmd > /dev/null 2>&1"
alias e="xdg-open ."
alias x=extract  #Function extract
alias q="exit"
alias dc="docker compose"
alias size="du -h --max-depth=1 . | sort -h"
alias http_serv="python3 -m http.server"
alias sshuttle="sshuttle --dns -vvr drakirus-gateway@prr.re 0/0"
alias paclean="sudo pacman -Rns \$(pacman -Qqtd)"

# NAS
alias backup-lab="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/lab /run/mount/NAS/xps13-Backup/"
alias backup-music="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/Musique /run/mount/NAS/xps13-Backup/"
alias backup-image="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/Images /run/mount/NAS/xps13-Backup/"
alias backup-resource="rsync -avPh --cvs-exclude --exclude-from="$HOME/.rsync.excludes" ~/resource /run/mount/NAS/xps13-Backup/"
alias nas="sudo mkdir -p /run/mount/NAS; sudo mount -t nfs -rw 192.168.1.55:/volume1/Share /run/mount/NAS/"
alias unas="sudo umount -l /run/mount/NAS"

alias tri="exiftool -if '\$rating >= 1' -d './tri' '-directory<createdate' ."
alias bt="sudo systemctl start bluetooth.service"
alias neof="neofetch --memory_display barinfo"
alias grip="grip --pass afab9ab158c3a52283f9bf2adfc2b6a3fe6286b2 -b"
alias mv="mv -iv"
alias cp="cp -aiv"
alias py="python"
alias py2="python2"
alias music="mpv ./* --shuffle --no-video"
alias df="df --exclude-type=tmpfs -h | grep -v loop"
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

alias t="cd /tmp"
alias tl="cd ~/Downloads"
alias dl="cd ~/Downloads"

alias ncdusys="sudo ncdu / --exclude \"/home/*\" --color dark -x --exclude .git --exclude node_modules"
alias ncdu="ncdu --color dark -x --exclude .git --exclude node_modules"

# ssh
alias atal="env TERM=tmux-256color ssh s142293@transit.univ-lemans.fr"
alias webai="ssh dialog@172.16.250.7"
alias g5k-all="env TERM=tmux-256color ssh -t pchampion@access.grid5000.fr ssh -t nancy "
alias g5k="env TERM=tmux-256color ssh pchampion@access.nancy.grid5000.fr"
alias lst="ssh pchampi@lst1"
alias cleps="env TERM=tmux-256color ssh -o "IdentitiesOnly=yes" -i ~/.ssh/id_ed25519 pchampio@cleps.inria.fr"


# cat ~/.ssh/id_rsa | ssh-key-on-line
alias ssh-key-on-line="openssl base64 | tr -d '\n'"
# echo $ONE-LINE-KEY | ssh-key-on-line-decode
alias ssh-key-on-line-decode="openssl base64 -A -d"

# alias cat="bat --theme=GitHub"
alias ping='prettyping --nolegend'

alias osc52clean='echo -e "\033]52;c;!\a"'
alias osc52='echo -e "\033]52;c;$(base64 <<< hello)\a"'

alias inria-screen-clean="inria-screen-all; sleep 4; inria-screen-one; killall 'latte-dock'; nohup latte-dock > /dev/null 2> /dev/null &"

alias sig="cat resources/sig | xsel -b --clipboard"

alias vpn='source <(echo "$($HOME/dotfiles/bin/rbw get cef664e1-feb8-4443-a536-2dc0c0ed1947)"); tmpfile=$(mktemp) ; echo -e "$meaning_vpn_user\n$meaning_vpn_pass" > $tmpfile ; sudo openvpn --config ~/.meaning_pierre_region-1.ovpn --auth-user-pass $tmpfile'

# lychee photos
# see ./abbreviations.zsh


# follow symlinks by default plus line number and file on the same line
rg () { command rg -z -L --no-heading "$@"; }

alias vim='nvim'
alias vi='nvim'
alias v='nvim'
