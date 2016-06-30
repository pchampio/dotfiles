# ------------------------------------------------------------------------------
#          FILE:  extract.plugin.zsh
#   DESCRIPTION:  oh-my-zsh plugin file.
#        AUTHOR:  Sorin Ionescu (sorin.ionescu@gmail.com)
#       VERSION:  1.0.1
# ------------------------------------------------------------------------------

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
  ssh -NR 22280:localhost:2280 ubuntu@drakirus.xyz 2>&1 &
  PID=$!

  # gotty ${args} -p 2280 -a $host -c pair:$passwd $cmd
  eval "gotty ${args} -p 2280 -a $host -c pair:$passwd $cmd"

  kill -9 $PID
}

function cpf {
  emulate -L zsh
  clipcopy $1
}

