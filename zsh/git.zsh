# Query/use custom command for `git`.
zstyle -s ":vcs_info:git:*:-all-" "command" _omz_git_git_cmd
: ${_omz_git_git_cmd:=git}

#
# Functions
#

# The name of the current branch
# Back-compatibility wrapper for when this function was defined here in
# the plugin, before being pulled in to core lib/git.zsh as git_current_branch()
# to fix the core -> git plugin dependency.
function current_branch() {
    git_current_branch
}
# The list of remotes
function current_repository() {
    if ! $_omz_git_git_cmd rev-parse --is-inside-work-tree &> /dev/null; then
        return
    fi
    echo $($_omz_git_git_cmd remote -v | cut -d':' -f 2)
}
# Pretty log messages
function _git_log_prettily(){
    if ! [ -z $1 ]; then
        git log --pretty=$1
    fi
}
# Warn if the current branch is a WIP
function work_in_progress() {
    if $(git log -n 1 2>/dev/null | grep -q -c "\-\-wip\-\-"); then
        echo "WIP!!"
    fi
}

#
# Aliases
# (sorted alphabetically)
#

prefix=""
[[ -f $HOME/.local/bin/ngit ]] && prefix="n"

alias g=${prefix}'git'

alias ga=${prefix}'git add'
alias gaa=${prefix}'git add --all'
alias gapa=${prefix}'git add --patch'
alias gau=${prefix}"git add -u"
alias gs=${prefix}"gdstst"
alias gpatch=${prefix}"git format-patch -1 HEAD"
alias git-size=${prefix}"git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '/^blob/ {print substr($0,6)}' | sort --numeric-sort --key=2 | cut --complement --characters=13-40 | numfmt --field=2 --to=iec-i --suffix=B --padding=7 --round=neares"

alias gb=${prefix}'git branch'
alias gba=${prefix}'git branch -a'
alias gbd=${prefix}'git branch -d'
alias gbda=${prefix}'git branch --no-color --merged | command grep -vE "^(\*|\s*(master|develop|dev)\s*$)" | command xargs -n 1 git branch -d'
alias gbl=${prefix}'git blame -b -w'
alias gbnm=${prefix}'git branch --no-merged'
alias gbr=${prefix}'git branch --remote'
alias gbs=${prefix}'git bisect'
alias gbsb=${prefix}'git bisect bad'
alias gbsg=${prefix}'git bisect good'
alias gbsr=${prefix}'git bisect reset'
alias gbss=${prefix}'git bisect start'

alias gc=${prefix}'ssh-add -L | grep -E ssh-ed25519 || ssh-add ~/.ssh/id_ed25519 && git commit -v'
alias gc!=${prefix}'git commit -v --amend'
alias gcn!=${prefix}'git commit -v --no-edit --amend'
alias gca=${prefix}'git commit -v -a'
alias gca!=${prefix}'git commit -v -a --amend'
alias gcan!=${prefix}'git commit -v -a --no-edit --amend'
alias gcans!=${prefix}'git commit -v -a -s --no-edit --amend'
alias gcam=${prefix}'git commit -a -m'
alias gcsm=${prefix}'git commit -s -m'
alias gcb=${prefix}'git checkout -b'
alias gcf=${prefix}'git config --list'
alias gcl=${prefix}'git clone --recursive'
alias gclean=${prefix}'git clean -fd'
alias gpristine=${prefix}'git reset --hard && git clean -dfx'
alias gcm=${prefix}'git checkout master'
alias gcd=${prefix}'git checkout develop'
alias gcmsg=${prefix}'git commit -m'
alias gco=${prefix}'git checkout'
alias gcount=${prefix}'git shortlog -sn'
alias gcp=${prefix}'git cherry-pick'
alias gcpa=${prefix}'git cherry-pick --abort'
alias gcpc=${prefix}'git cherry-pick --continue'
alias gcs=${prefix}'git commit -S'

alias gd=${prefix}'git diff'
alias gdca=${prefix}'git diff --cached'
alias gdct=${prefix}'git describe --tags `git rev-list --tags --max-count=1`'
alias gdt=${prefix}'git diff-tree --no-commit-id --name-only -r'
alias gdw=${prefix}'git diff --word-diff'

alias gf=${prefix}'git fetch'
alias gfa=${prefix}'git fetch --all --prune'
alias gfo=${prefix}'git fetch origin'

alias gg=${prefix}'git gui citool'
alias gga=${prefix}'git gui citool --amend'

alias gl=${prefix}'git pull'
alias glg=${prefix}'git log --stat'
alias glgp=${prefix}'git log --stat -p'
alias glgg=${prefix}'git log --graph'
alias glgga=${prefix}'git log --graph --decorate --all'
alias glgm=${prefix}'git log --graph --max-count=10'
alias glo=${prefix}'git log --oneline --decorate'
alias glol=${prefix}"git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glola=${prefix}"git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all"
alias glog=${prefix}'git log --oneline --decorate --graph'
alias gloga=${prefix}'git log --oneline --decorate --graph --all'
alias glp=${prefix}"_git_log_prettily"
alias gm=${prefix}'git merge'
alias gmom=${prefix}'git merge origin/master'
alias gmt=${prefix}'git mergetool --no-prompt'
alias gmtvim=${prefix}'git mergetool --no-prompt --tool=vimdiff'
alias gmum=${prefix}'git merge upstream/master'

alias gp=${prefix}'git push'
alias gpd=${prefix}'git push --dry-run'
alias gpoat=${prefix}'git push origin --all && git push origin --tags'
alias gpu=${prefix}'git push upstream'
alias gpv=${prefix}'git push -v'

alias gr=${prefix}'git remote'
alias gra=${prefix}'git remote add'
alias grb=${prefix}'git rebase'
alias grba=${prefix}'git rebase --abort'
alias grbc=${prefix}'git rebase --continue'
alias grbi=${prefix}'git rebase -i'
alias grbm=${prefix}'git rebase master'
alias grbs=${prefix}'git rebase --skip'
alias grh=${prefix}'git reset HEAD'
alias grhh=${prefix}'git reset HEAD --hard'
alias grmv=${prefix}'git remote rename'
alias grrm=${prefix}'git remote remove'
alias grset=${prefix}'git remote set-url'
alias grt='cd $(git rev-parse --show-toplevel || echo ".")'
alias gru=${prefix}'git reset --'
alias grup=${prefix}'git remote update'
alias grv=${prefix}'git remote -v'

alias gsb=${prefix}'git status -sb'
alias gsd=${prefix}'git svn dcommit'
alias gsi=${prefix}'git submodule init'
alias gsps=${prefix}'git show --pretty=short --show-signature'
alias gsr=${prefix}'git svn rebase'
alias gss=${prefix}'git status -s'
alias gst=${prefix}'git status'
alias gsta=${prefix}'git stash save'
alias gstaa=${prefix}'git stash apply'
alias gstc=${prefix}'git stash clear'
alias gstd=${prefix}'git stash drop'
alias gstl=${prefix}'git stash list'
alias gstp=${prefix}'git stash pop'
alias gsts=${prefix}'git stash show --text'
alias gsu=${prefix}'git submodule update'

alias gts=${prefix}'git tag -s'
alias gtv=${prefix}'git tag | sort -V'

alias gunignore=${prefix}'git update-index --no-assume-unchanged'
alias gunwip=${prefix}'git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
alias gup=${prefix}'git pull --rebase'
alias gupv=${prefix}'git pull --rebase -v'
alias glum=${prefix}'git pull upstream master'

alias gwch=${prefix}'git whatchanged -p --abbrev-commit --pretty=medium'
alias gwip=${prefix}'git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify -m "--wip-- [skip ci]"'
