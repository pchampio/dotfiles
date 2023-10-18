#!/bin/bash

docker run --rm -ti --tty=true \
  -v ~/.cache/rbw/tmp-rbw-1000:/tmp/rbw-1000 \
  -v ~/.cache/rbw/home-rbw-.config:/home/rbw/.config \
  -v ~/.cache/rbw/home-rbw-.local:/home/rbw/.local \
  -v ~/.cache/rbw/home-rbw-.cache:/home/rbw/.cache \
  -e UID=$(id -u) \
  git.prr.re/drakirus/rbw:1.0 \
  /setup.sh
