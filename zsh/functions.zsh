function nvim() {
  if [[ "$#" == 0 ]]; then
    $HOME/dotfiles/bin/nvim;
  else
    OWNER=$(stat -c '%U' $1)
    if [[ "$OWNER" == "root" ]]; then
      echo -e "\e[3m\033[1;31mMust be root to edit the file! \033[0m \e[23m"
      sleep 0.3
      sudoedit $*;
    else
      $HOME/dotfiles/bin/nvim $*;
    fi
  fi
}

function kkey(){
   delay=$(xfconf-query -c keyboards -p /Default/KeyRepeat/Delay)
   xfconf-query -c keyboards -p /Default/KeyRepeat/Delay -s $(($delay+1))
}

function nvimux-vim() {
  if [[ "$#" == 0 ]]; then
    nvr -c "CtrlP `pwd`"
    return
  fi
  nvr $*
}


function gdstst(){
  awk -vOFS='' '
    NR==FNR {
        all[i++] = $0;
        difffiles[$1] = $0;
        next;
    }
    ! ($2 in difffiles) {
        print; next;
    }
    {
        gsub($2, difffiles[$2]);
        print;
    }
    END {
        if (NR != FNR) {
            # Had diff output
            exit;
        }
        # Had no diff output, just print lines from git status -sb
        for (i in all) {
            print all[i];
        }
    }
  ' \
    <(git diff --color --stat HEAD | sed '$d; s/^ //')\
    <(git -c color.status=always status -sb)
  }

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

  if [[ $# -eq 1 ]]; then
    cmd=$1
  fi

  # Share
  echo "https://2280.proxme.drakirus.com/"
  ssh -NR 2280:localhost:2280 share@drakirus.com 2>&1 &
  PID=$!

  # gotty ${args} -p 2280 -a $host -c pair:$passwd $cmd
  eval "gotty ${args} -p 2280 -c pair:$passwd $cmd"

  kill -9 $PID
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

net-list(){
  echo "Please, select a network interface:"
  select interface in `ls /sys/class/net/ | cut -d/ -f4`; do
  echo $interface selected
  ip=`ip address show eth0 | grep 'inet ' | sed 's/  */ /g' | cut -d" " -f 3 | tr "\n" " "`
  break
  done
  vared -p 'Enter the network and press [ENTER]: ' -c ip
  sudo nmap -sP $ip
}

docker-enter () {
  docker exec -ti $1 sh
}


ff() { find . -name "*$1*" -ls; }
ffrm() { find . -name "*$1*" -exec rm {} +; }

function mm() {
  mpv --ytdl --loop --no-video "$@"
}

function yt-dl (){
  youtube-dl --extract-audio --prefer-ffmpeg  --audio-format mp3  "$1"
}

function jpgg(){
  cp -as `ls -d -1 $PWD/**/tri/**/* | grep jpg` ./jpg
}

function xbox() {
  sudo systemctl start bluetooth.service
  echo -e "power on" | bluetoothctl
}

function juv() {
  UUID=$(echo $(uuidgen) | cut -d"-" -f1)
  BASE=$(basename $1)

  jupyter nbconvert --to python "$1" --output "/tmp/$UUID-$BASE"
  nvim "/tmp/$UUID-$BASE.py"
}

function drak-todo() {
  gotify push "TODO" --title "$1" --priority="5"
}

function aspec-all() {
  for file in *.wav; do
    aspec $file
  done
}

##########
#  MOSH  #
##########

function mosh-relay-server() {
  RELAY="163.172.164.152" # drakirus.com
  PORT="$(seq 34730 2 34830 | shuf -n 1)"
  kill -9 $(lsof -t -i:$PORT)
  echo -n 'nat-hole-punch' | socat STDIN "UDP-SENDTO:$RELAY:$PORT,sourceport=$PORT"
  key=$(env TMUX='' mosh-server new -p "$PORT" | sed -n 's/MOSH CONNECT [0-9]\+ \(.*\)$/\1/g p')
  cmd="MOSH_KEY=$key mosh-client 163.172.164.152 $(($PORT + 1))"
  echo "Connect using $ $cmd"

  # uses osc52 to copy cmd to host
  echo -e "\033]52;c;$(base64 <<< $cmd)\a"
}
