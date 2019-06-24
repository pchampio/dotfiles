#! /usr/bin/env zsh

compdef _jd jd

chpwd_functions+=(storepwd)

dir="$HOME/dotfiles/bin"

function storepwd {
  $(ruby ${dir}/jumpdir.rb --incdir $(pwd) > /dev/null 2>&1 &)
}

function jc {
  if [[ -n "$1" ]]; then
    cd $(ruby ${dir}/jumpdir.rb --jumpchild $1)
  fi
}

function jd {
  cd $(ruby ${dir}/jumpdir.rb --jumpdir $1)
}

function jm {
  cd $(ruby ${dir}/jumpdir.rb --jumpmark $1)
}

function m {
  ruby ${dir}/jumpdir.rb --markdir $1
}

function _jd {
  compadd -U $(ruby ${dir}/jumpdir.rb --complete $PREFIX)
}
