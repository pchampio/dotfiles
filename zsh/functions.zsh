size_threshold=5000000
function nvim() {
    if [[ "$#" == 0 ]]; then
        $HOME/dotfiles/bin/nvim-linux64/bin/nvim;
    else
        if [[ ! -f "$1" ]]; then
            $HOME/dotfiles/bin/nvim-linux64/bin/nvim $*;
            return
        fi
        file_size=$(stat -c %s "$1")
        if [ "$file_size" -gt "$size_threshold" ]; then
            # --startuptime vim.log 
            large_file_disable_plugin=false $HOME/dotfiles/bin/nvim-linux64/bin/nvim $* ;
        else
            large_file_disable_plugin=true $HOME/dotfiles/bin/nvim-linux64/bin/nvim $*;
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

# Show all 256 colors with color number
function spectrum_ls() {
    for code in {000..255}; do
        print -P -- "$code: %F{$code}Test%f"
    done
}

function proxme() {
    cat << EOF
                                .
                               *
.oPYo.  ' oPYo. .oPYo. \`o  o'    ooYoYo. .oPYo
8    8   8  \`' 8    8  \`bd'     8' 8  8 8oooo8
o    *  8     8    8  d'\`b     8  8  8 8.
88Y0P   8     \`YooP' o'  \`o    8  8  8 \`Yooo'
8
8                     Dead simple public URLs

- only port 2222 is exposed on the prr.re host.
  (usefull for non-http service)

EOF

    port=8080
    vared -p ' Share local port: ' -c port
    proxmeport=$port
    vared -p ' On proxme port : ' -c proxmeport


    if [[ $proxmeport = '2222' ]]
    then
        echo " Usage example of non http port fowrarding:"
        echo "  rsync -avzh --progress -e 'ssh -p 2222' /PATH_FILE_SEND $(whoami)@prr.re:~/OUT --dry-run"
    else

        if ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null; then
            echo -n " Start python3 http server on $port [default Yes]: "
            read inputs
            if [[ $inputs =~ ^([Nn][oO]|[nN])$ ]]
            then
                echo " Not starting the http server"
            else
                echo " Starting http server on port $port.."
                python3 -m http.server $port &
            fi
        fi

        echo " --> https://$proxmeport.proxme.prr.re/"
    fi
    ssh -R "${proxmeport}:localhost:${port}" share@prr.re
    fg
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
    echo "https://2280.proxme.prr.re/"
    ssh -NR 2280:localhost:2280 share@prr.re 2>&1 &
    PID=$!

    # gotty ${args} -p 2280 -a $host -c pair:$passwd $cmd
    eval "gotty ${args} -p 2280 -c pair:$passwd $cmd"

    kill -9 $PID
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
    PORT="$(seq 7000 4 7050 | shuf -n 1)"
    kill -9 $(lsof -t -i:${PORT})
    kill -9 $(lsof -t -i:$(($PORT + 1)))
    tcp2udp --tcp-listen  0.0.0.0:$PORT --udp-forward 0.0.0.0:$(($PORT + 1)) &
    key=$(TMUX='' MOSH_SERVER_NETWORK_TMOUT=604800 MOSH_SERVER_SIGNAL_TMOUT=604800 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 /tmp/mo/mosh-server new -p "$(($PORT + 1))"  -- /bin/zsh | sed -n 's/MOSH CONNECT [0-9]\+ \(.*\)$/\1/g p')
    cmd="ssh -L $(($PORT + 2)):localhost:$(($PORT + 2)) share@prr.re &; udp2tcp --udp-listen 0.0.0.0:$(($PORT + 3)) --tcp-forward 0.0.0.0:$(($PORT + 2)) &; LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 MOSH_KEY=$key mosh-client 0.0.0.0 $(($PORT + 3))"
    echo "Connect using $ $cmd"

    # uses osc52 to copy cmd to host
    echo -e "\033]52;c;$(base64 <<< $cmd)\a"
    ssh -R $(($PORT + 2)):localhost:$PORT share@prr.re
    kill $(ps -s $$ -o pid=)
}

kill-port() {
  local pid
  pid=$(lsof -n -i -P | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

bw_totp_1() {
    echo "Loading bitwarden"
    token=$(rbw get "32d66a6f-ef01-4835-8ad1-aae19fa717a7" --field 'totp')
    echo "$token" | xclip -selection c
    echo "Token copied"
}
