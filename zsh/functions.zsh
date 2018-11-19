
# AUTHOR:  Sorin Ionescu (sorin.ionescu@gmail.com)
function extract() {
  local remove_archive
  local success
  local file_name
  local extract_dir

  if (( $# == 0 )); then
    echo "Usage: extract [-option] [file ...]"
    echo
    echo Options:
    echo "    -r, --remove    Remove archive."
    echo
    echo "Report bugs to <sorin.ionescu@gmail.com>."
  fi

  remove_archive=1
  if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi

  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" 1>&2
      shift
      continue
    fi

    success=0
    file_name="$( basename "$1" )"
    extract_dir="$( echo "$file_name" | sed "s/\.${1##*.}//g" )"
    case "$1" in
      (*.tar.gz|*.tgz) [ -z $commands[pigz] ] && tar zxvf "$1" || pigz -dc "$1" | tar xv ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
      (*.tar.xz|*.txz) tar --xz --help &> /dev/null \
        && tar --xz -xvf "$1" \
        || xzcat "$1" | tar xvf - ;;
      (*.tar.zma|*.tlz) tar --lzma --help &> /dev/null \
        && tar --lzma -xvf "$1" \
        || lzcat "$1" | tar xvf - ;;
      (*.tar) tar xvf "$1" ;;
      (*.gz) [ -z $commands[pigz] ] && gunzip "$1" || pigz -d "$1" ;;
      (*.bz2) bunzip2 "$1" ;;
      (*.xz) unxz "$1" ;;
      (*.lzma) unlzma "$1" ;;
      (*.Z) uncompress "$1" ;;
      (*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk) unzip "$1" -d $extract_dir ;;
      (*.rar) unrar x -ad "$1" ;;
      (*.7z) 7za x "$1" ;;
      (*.deb)
        mkdir -p "$extract_dir/control"
        mkdir -p "$extract_dir/data"
        cd "$extract_dir"; ar vx "../${1}" > /dev/null
        cd control; tar xzvf ../control.tar.gz
        cd ../data; tar xzvf ../data.tar.gz
        cd ..; rm *.tar.gz debian-binary
        cd ..
      ;;
      (*)
        echo "extract: '$1' cannot be extracted" 1>&2
        success=1
      ;;
    esac

    (( success = $success > 0 ? $success : $? ))
    (( $success == 0 )) && (( $remove_archive == 1 )) && rm "$1"
    shift
  done
}

typeset -Ag FX FG BG

FX=(
    reset     "%{[00m%}"
    bold      "%{[01m%}" no-bold      "%{[22m%}"
    italic    "%{[03m%}" no-italic    "%{[23m%}"
    underline "%{[04m%}" no-underline "%{[24m%}"
    blink     "%{[05m%}" no-blink     "%{[25m%}"
    reverse   "%{[07m%}" no-reverse   "%{[27m%}"
)

for color in {000..255}; do
    FG[$color]="%{[38;5;${color}m%}"
    BG[$color]="%{[48;5;${color}m%}"
done

# Show all 256 colors with color number
function spectrum_ls() {
  for code in {000..255}; do
    print -P -- "$code: %F{$code}Test%f"
  done
}

# Share your terminal as a web application
# https://github.com/yudai/gotty
#
# ON HOST/CLIENT
#   GatewayPorts yes
#   AllowTcpForwarding yes
share() {
  cmd="tmux -2 attach-session -t `tmux display -p '#S'`"
  echo "User = pair"
  unset TMUX;

  passwd=pierre
  args=""
  host="localhost"

  vared -p ' Password : ' -c passwd
  echo -n '\nAllow inputs [default no] : '
  read inputs
  if [[ $inputs =~ ^([yY][eE][sS]|[yY])$ ]]
  then
    echo -n '\nAccept only one client [default yes] : '
    read inputs
    cmd="tm"
    args+="-w"
    if [[ $inputs =~ ^([Nn][oO]|[nN])$ ]]
    then
    else
      args+=" --once"
    fi
  fi

  # When you send secret information through GoTTY, we strongly recommend you use the -t option
  # echo -n '\nEnables TLS/SSL [default no] : '
  # read inputs
  # if [[ $inputs =~ ^([yY][eE][sS]|[yY])$ ]]
  # then
    # args+=" -t"
    # if [[ ! -f ~/.gotty.key ]]; then
      # echo -n "\nNeed ->  openssl req -x509 -nodes -days 9999 -newkey rsa:2048 -keyout ~/.gotty.key -out ~/.gotty.crt\n"
      # exit
    # fi
  # fi

  if [[ $# -eq 1 ]]; then
    cmd=$1
  fi

  # Share
  ssh -NR 2280:0.0.0.0:2280 drakirus@drakirus.com 2>&1 &
  PID=$!

  # gotty ${args} -p 2280 -a $host -c pair:$passwd $cmd
  eval "gotty ${args} -p 2280 -c pair:$passwd $cmd"

  kill -9 $PID
}

v() {

  if [ -z ${TMUX+x} ]; then
    vim $@
    return
  fi

  VIM_PANE=`tmux list-panes -F '#{pane_id} #{pane_current_command}'\
    | grep -i 'vim' | cut --d=" " --f=1`
  if [ -z $VIM_PANE ]; then
    vim $@
  else
    for file in $@; do
      tmux send-keys -t $VIM_PANE Escape
      tmux send-keys -t $VIM_PANE \;vsplit\ `realpath $file`
      tmux send-keys -t $VIM_PANE Enter
      shift
    done
  fi
}

zoomInVim() {
  VIM_PANE=`tmux list-panes -F '#{pane_id} #{pane_current_command}'\
    | grep -i 'vim' | cut --d=" " --f=1`
ome -new command
tmux send-keys -t $VIM_PANE Escape
  tmux send-keys -t $VIM_PANE \;vsplit\ `realpath $file`
  tmux send-keys -t $VIM_PANE Enter
}

thunarCmd(){
  WINTITLE="Gestionnaire de fichiers" # Main 'app' window has this in titlebar
  PROGNAME="thunar" # This is the name of the binary for 'app'

  # Use wmctrl to list all windows, count how many contain WINTITLE,
  # and test if that count is non-zero:

  if [ `wmctrl -l | grep -c "$WINTITLE"` != 0 ]
  then
    wmctrl -a "$WINTITLE" # If it exists, bring 'app' window to front
    sleep 0.2
    xdotool key ctrl+t
    xdotool key ctrl+l
    xdotool type "$(pwd)"
    xdotool key KP_Enter
  else
    thunar > /dev/null 2>&1 &  # Otherwise, just launch 'app'
  fi
}

clpset(){
  read -d"" text
  print `curl --silent --data "clp=$text" http://drakirus.xyz:8808`
}

clpget(){
  A=`curl --silent http://drakirus.xyz:8808`
  print $A
  echo $A > /tmp/clp.tmp
  xclip -in -selection clipboard /tmp/clp.tmp
}

net-list(){
  echo "Please, select a network interface:"
  select interface in `ls /sys/class/net/ | cut -d/ -f4`; do
    echo $interface selected
    ip=`ifconfig $interface | grep 'inet ' | sed 's/  */ /g' | cut -d" " -f 3`
    break
  done
  vared -p 'Enter the network and press [ENTER]: ' -c ip
  sudo nmap -sP $ip/24
}

docker-enter () {
  docker exec -ti $1 sh
}

svn-clean () {
  svn st | grep ! | cut -d! -f2| sed 's/^ *//' | sed 's/^/"/g' | sed 's/$/"/g' | xargs svn rm
}


ff() { find . -name "*$1*" -ls; }
ffrm() { find . -name "*$1*" -exec rm {} +; }

ffig() { find . -name "*$1*" -ls| grep -vFf skip_files; }

nhh () {
  old=$(xfconf-query -c xfce4-notifyd -p /do-not-disturb)
  if [[ $old == "true" ]]; then
    xfconf-query -c xfce4-notifyd -p /do-not-disturb -T
    notify-send  --expire-time=10 -i "notification-alert-symbolic" 'Notification' 'Ne pas déranger est désactivée'
  else
    notify-send --expire-time=10 -i "/usr/share/icons/Adwaita/24x24/status/audio-volume-muted-symbolic.symbolic.png" 'Notification' 'Ne pas déranger est activée'
    xfconf-query -c xfce4-notifyd -p /do-not-disturb -T
  fi
}

function mmpl() {
  mpv -no-video --shuffle --loop "$@"
}

function mm() {
    mpv --ytdl --loop --no-video "$@"
}

function yt-dl (){
  youtube-dl --extract-audio --prefer-ffmpeg  --audio-format mp3  "$1"
}

function rand-music (){
  cat /dev/urandom | hexdump -v -e '/1 "%u\n"' | awk '{ split("0,2,4,5,7,9,11,12",a,","); for (i = 0; i < 1; i+= 0.0001) printf("%08X\n", 100*sin(1382*exp((a[$1 % 8]/12)*log(2))*i)) }' | xxd -r -p | aplay -c 2 -f S32_LE -r 16000;
}

function jpgg(){
  cp -as `ls -d -1 $PWD/**/tri/**/* | grep jpg` ./jpg
}

function kkey(){
  delay=$(xfconf-query -c keyboards -p /Default/KeyRepeat/Delay)
  xfconf-query -c keyboards -p /Default/KeyRepeat/Delay -s $(($delay+1))
}

function adb-wifi(){

  sudo adb kill-server
  sudo adb usb
  sudo adb devices
  echo -n '\n Allow debug on the devices'
  read inputs
  sudo adb -d tcpip 5555
  sudo adb connect 192.168.240."$1":5555
  sudo adb devices
  sudo adb kill-server
  echo -n '\n Pls unplug'
  read inputs
  sudo adb connect 192.168.240."$1":5555
}

function dialog() {

  unset password
  echo "Password for p.champion:"
  read -s password

  mkdir -p ~/smb/HOTH/users
  sudo mount -t cifs //hoth/Users /home/drakirus/smb/HOTH/users -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/HOTH/Gabarits
  sudo mount -t cifs //hoth/Gabarits /home/drakirus/smb/HOTH/Gabarits -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/HOTH/Temp
  sudo mount -t cifs //hoth/Temp /home/drakirus/smb/HOTH/Temp -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/HOTH/Customers
  sudo mount -t cifs //hoth/Customers /home/drakirus/smb/HOTH/Customers -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/dev02/wwwroot
  sudo mount -t cifs //dev02/wwwroot /home/drakirus/smb/dev02/wwwroot -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/dev02/shibboleth-sp
  sudo mount -t cifs //dev02/shibboleth-sp /home/drakirus/smb/dev02/shibboleth-sp -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/ITHOR/wwwroot
  sudo mount -t cifs //ITHOR/wwwroot /home/drakirus/smb/ITHOR/wwwroot -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/ITHOR/Memberz
  sudo mount -t cifs //ITHOR/Memberz /home/drakirus/smb/ITHOR/Memberz -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

  mkdir -p ~/smb/HOTH/Docs
  sudo mount -t cifs //hoth/Docs /home/drakirus/smb/HOTH/Docs -o user=p.champion,password=${password},vers=1.0,file_mode=0777,dir_mode=0777

}

function udialog() {
  sudo umount -a -t cifs -l ~/smb/
}

function sound(){
  echo 0 | sudo tee /sys/module/snd_hda_intel/parameters/power_save
}

function sdelete(){
  svn rm $( svn status | sed -e '/^!/!d' -e 's/^!//' )
}

transfer() { if [ $# -eq 0 ]; then echo -e "No arguments specified. Usage:\necho transfer /tmp/test.md\ncat /tmp/test.md | transfer test.md"; return 1; fi
tmpfile=$( mktemp -t transferXXX ); if tty -s; then basefile=$(basename "$1" | sed -e 's/[^a-zA-Z0-9._-]/-/g'); curl --progress-bar --upload-file "$1" "https://transfer.sh/$basefile" >> $tmpfile; else curl --progress-bar --upload-file "-" "https://transfer.sh/$1" >> $tmpfile ; fi; cat $tmpfile; rm -f $tmpfile; }

function xbox() {
  sudo systemctl start bluetooth.service
  echo -e "power on" | bluetoothctl
}
