# Copyright (c) 2015 Antonio Murdaca <me@runcom.ninja>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# local curcontext=$curcontext state line
declare -A opt_args

_docker_running_containers() {
  compadd "$@" $(docker ps | perl -ne '@cols = split /\s{2,}/, $_; printf "%20s\n", $cols[6]' | tail -n +3 | awk '$1' | xargs)
}

_docker_enter () {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments '1: :->command'

  case $state in
    command) _docker_running_containers ;;
    *) ;;
  esac

  return 0
}

docker-enter () {
  docker exec -ti $1 sh
}

compdef _docker_enter docker-enter
