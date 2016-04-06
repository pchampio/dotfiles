Dotfiles
===================
![screenshot](https://github.com/Drakirus/dotfiles/blob/master/screenshot.png)
(Here's what my setup looks like)

## Installation

#### Clone
Clone this repo (or your own fork!) to your **home** directory (`/Users/username`).

```
$ cd ~
$ git clone https://github.com/Drakirus/dotfiles.git dotfiles
$ chmod +x -R dotfiles/install
```

#### Dotfiles

RC file (dotfile) management.  
(this command expects that you cloned your dotfiles to `~/dotfiles/`)
```
$ ~/dotfiles/install/dotfiles
```
It creates symlinks ex.(`.vimrc` -> `/dotfiles/vimrc`) from your home directory to your `/dotfiles/` directory.  

### Vim Plugins
Plugins are listed in `vimrc.bundles`.
```
$ ~/dotfiles/install/vimBundle
```
> Used to Install / Update / Clean all vim's Plugins

### Apt-Installll
```
$ cd ~/dotfiles/
$ ./install/....
```
You can chose to install :
* Atom with my usual plugins
* Atom remote (useful on serveur)
* Java :grimacing:
* Node Js
   * with [tldr-man-pages](https://github.com/tldr-pages/tldr)
* Dotfiles
* Vim-bundles (Installation of vim Plugins with vundle)
* xfce (just my own tweaks)
* zsh :heart:


### Git Config
Make sure you update `gitconfig` with your own name and email address. Otherwise you'll be committing as me. :smile_cat:  
`git config --global core.excludesfile ~/.gitignore`  
`git config --global commit.template ~/.gitmessage`  

### Custom Fonts
You'll need to use a custom font for Airline to look nice. (Seeing weird symbols? This is why!).  
See here: https://github.com/Lokaltog/powerline-fonts
> I use *hack* (size 12).  
> Get the icons fonts used in NerdTree here: https://github.com/ryanoasis/nerd-fonts#font-installation

### Recommended

**Wemux**

https://github.com/zolrath/wemux

**Tmux**
```
$ sudo apt-get install tmux
```

For OSX,
```
# Add this to tmux.conf
set-option -g default-command "reattach-to-user-namespace -l zsh -l"
# one more
$ brew install reattach-to-user-namespace
```
---
These are a modified version of Thoughtbot's dotfiles.  
More detailed instructions are available here:  
https://github.com/mscoutermarsh/dotfiles
http://github.com/thoughtbot/dotfiles
