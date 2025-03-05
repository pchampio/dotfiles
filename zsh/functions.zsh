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
        (( $success == 0 )) && (( $remove_archive == 1 )) && \rm "$1"
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
    command ssh -R "${proxmeport}:localhost:${port}" share@prr.re
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
    command ssh -NR 2280:localhost:2280 share@prr.re 2>&1 &
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

ff() { find . -name "*$1*" -ls; }
ffrm() { find . -name "*$1*" -exec rm {} +; }

function mm() {
    mpv --ytdl --loop --no-video "$@"
}

function jpgg(){
    cp -as `ls -d -1 $PWD/**/tri/**/* | grep jpg` ./jpg
}

function xbox() {
    sudo systemctl start bluetooth.service
    echo -e "power on" | bluetoothctl
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

sssh() {
    command ssh $@
}

ssh() {
    set -o pipefail
    # set +o pipefail # invert
    line_count=$(ssh-add -l 2> /dev/null | wc -l )
    if [ $? -eq 2 ]; then
        eval $(<~/.ssh-agent-thing) > /dev/null
        line_count=$(ssh-add -l 2> /dev/null | wc -l)
        if [ $? -eq 2 ]; then
            ssh-agent > ~/.ssh-agent-thing
            eval $(<~/.ssh-agent-thing) > /dev/null
            line_count=$(ssh-add -l | wc -l)
        fi
    fi
    if [ "$line_count" -ge 2 ] && [ $# -ne 0 ]; then
        command ssh $@
        return
    fi
    echo "Using vault to get the ssh keys (Use sssh otherwise)"
    rbw unlock
    rbw get "6ed8aac4-1443-43ed-b42e-c484ca281610" --field 'raw_id_ed25519' | base64 --decode | ~/.local/share/junest/bin/junest --  SSH_PASS=$(rbw get "6ed8aac4-1443-43ed-b42e-c484ca281610" --field 'Ed25519.passphrase') DISPLAY=1 SSH_ASKPASS=$HOME/dotfiles/bin/auto-add-key ssh-add -t 6h  -
    rbw get "6ed8aac4-1443-43ed-b42e-c484ca281610" --field 'raw_id_rsa' | base64 --decode | ~/.local/share/junest/bin/junest --  SSH_PASS=$(rbw get "6ed8aac4-1443-43ed-b42e-c484ca281610" --field 'RSA.passphrase') DISPLAY=1  SSH_ASKPASS=$HOME/dotfiles/bin/auto-add-key ssh-add -t 6h  -
    if [ $# -ne 0 ]; then
        command ssh $@
        return
    fi
}

__cd() {
    # Save the current chpwd function
    saved_chpwd=$(typeset -f chpwd)
    # Unset the chpwd function
    unset -f chpwd
    # Run the desired command
    cd $1
    # Restore the chpwd function
    eval "$saved_chpwd"
}

nvidia-kill() {

    header=$(cat << "EOF"
PID    GPU Memory,Command,User
Kill nvidia-smi processes
('alt-enter' to select-all and kill)
EOF
    )
    nvidia-smi | awk '/Processes/ {p=1} p && !/^\+/{print}' | tail -n +5 | \
    awk '{printf "%-11s %-8s %-8s %-12s\n", $2, $5, $8, $11}' | \
    while read -r gpu pid mem user; do \
        ps -o pid= -o user= -o comm= -p $pid | \
        awk -v gpu=$gpu -v mem=$mem '{print $1, gpu, mem, $3, $2}'; \
    done | \
    sort -k2,2 -k3,3nr | \
    column -t | \
    fzf --bind='alt-enter:select-all+accept' --header "$header" --multi | \
    awk '{print $1}' | xargs kill -9
}
