My . Files
===================
![Fullscreen](https://raw.githubusercontent.com/Drakirus/dotfiles/master/screenshot.png)  
(Here's what my setup looks like)

## ShutdownHook 

Add `shutdown` to the hooks in `/etc/mkinitcpio.conf` and regenerating (`mkinitcpio -p linux`)

## Mouse

```sh
# config range
less /var/log/Xorg.0.log | grep -i range
# Palm detection config
synclient PalmDetect=1 PalmMinWidth=0 PalmMinZ=0
# disable Right side of trackpad
synclient AreaLeftEdge=100 AreaRightEdge=850 AreaTopEdge=70
```
> /etc/X11/xorg.conf.d/10-synaptics.conf
``` conf
Section "InputClass"
Identifier "touchpad catchall"
Driver "synaptics"
MatchIsTouchpad "on"
# Option "PalmDetect" "1"
Option "MaxSpeed" "1"
Option "AreaLeftEdge" "50"
Option "AreaRightEdge" "850"
Option "AreaTopEdge" "50"
Option "HorizTwoFingerScroll" "on"
Option "VertScrollDelta" "40"
Option "HorizScrollDelta" "120"
EndSection

```

## Installation

#### Clone
Clone this repo (or your own fork!) to your **home** directory (`/home/{USERNAME}/dotfiles`).

``` sh
cd ~
git clone https://github.com/Drakirus/dotfiles.git dotfiles
chmod +x -R dotfiles/install
```

#### Dotfiles

RC file (dotfile) management.  
(this command expects that you cloned your dotfiles to `~/dotfiles/`)

``` sh
~/dotfiles/install/dotfiles
```

It creates symlinks ex.(`.vimrc` -> `~/dotfiles/vimrc`) from your home directory to your `~/dotfiles/` directory.  

### Vim

```
~/dotfiles/install/vimplug
```

> Used to Install / Update / Clean all vim's Plugins

``` sh
sudo apt-get install libluajit-5.1
make distclean
./configure --enable-luainterp=yes \
--with-features=huge \
--enable-rubyinterp \
--enable-pythoninterp \
--enable-python3interp \
--enable-perlinterp
make
sudo make install
```

> Used to install vim

### Apt-Installll

``` sh
$ cd ~/dotfiles/
$ ./install/....
```

You can choose to install :  
* Atom with my usual plugins
* Node Js
   * with [tldr-man-pages](https://github.com/tldr-pages/tldr)
* Dotfiles
* Vim-Plugins (Installation of vim Plugins with [Vim-Plug](https://github.com/junegunn/vim-plug))
* xfce (just my own tweaks)
* zsh :heart:


### Git Configuration
Make sure you update `gitconfig` with your own name and email address otherwise, you'll be committing as me. :smile_cat:  
`git config github.user {USERNAME}`  
`git config --global core.excludesfile ~/.gitignore`  
`git config --global commit.template ~/.gitmessage`  

### Custom Fonts
https://github.com/vikky49/patchedFonts-Ligatures

---

### Jupyter notebook
```
pip install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master --user
pip install jupyter_nbextensions_configurator --user
pip install autopep8 --user
```

### Terminal emulator

```
setxkbmap -option caps:escape &
```


```
for x in $(cat package.list); do pacman -S $x; done
```

https://www.archlinux.org/packages/community/x86_64/termite/  



terminus.vim
```
inoremap <expr><f20> pumvisible() ? "<c-e><c-o>:silent doautocmd <nomodeline> FocusLost %<cr>" : "<c-o>:silent doautocmd <nomodeline> FocusLost %<cr>"

```

bash
`PS1='\[\e[32m\u\] \[\e[36m\w\] \[\e[33m\]\[\e[1m\]$ \[\e[0m\]'`

clock.xfce.panel

```
<span  font='8.'>%d-%m-%Y%n</span><span  font_weight='ultrabold'>%R</span>
```


These are a modified version of Thoughtbot's dotfiles.  
More detailed instructions are available here:  
https://github.com/mscoutermarsh/dotfiles /
http://github.com/thoughtbot/dotfiles


## Nvim

```
wget https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage --output-document nvim
chmod +x nvim
sudo chown root:root nvim
sudo mv nvim /usr/bin
```



## Firefox

Alt key map

[about:config?filter=ui.key.menuAccessKeyFocuses](about:config?filter=ui.key.menuAccessKeyFocuses) -> to false

## Disable GRUB delay

```sh
sudo vim /etc/default/grub
# set: GRUB_TIMEOUT=0
sudo update-grub
```

## Reduce swappiness
Optimize the use of Swap and RAM.

```sh
cat /proc/sys/vm/swappiness
sudo vim /etc/sysctl.d/100-manjaro.conf
# add line: vm.swappiness=10
```

## Enable TRIM for SSD
TRIM is a program that helps to clean blocks in your SSD and thus use it more efficiently and extend the SSD’s life.

```sh
sudo systemctl enable fstrim.timer
```

## systemd timeout
Reduce the default timeout(90s) for starting, stopping and aborting of units.

```sh
sudo vim /etc/systemd/system.conf 
# set: DefaultTimeoutStartSec=10s
# set: DefaultTimeoutStopSec=5s
```

## Linux Disable Core Dumps

```sh
sudo vim /etc/systemd/coredump.conf
set: Storage=none
set: ProcessSizeMax=0
sudo systemctl daemon-reload
```


Disable file search in KDE Kickoff Launcher

```sh
sudo vim /usr/share/kservices5/plasma-runner-baloosearch.desktop
# set : X-KDE-PluginInfo-EnabledByDefault=false
```


# KDE
# CPU Undervolting 

kde gtk3 theme: https://store.kde.org/p/1181106/ Plane Gtk-3.20+

https://wiki.archlinux.org/index.php/Undervolting_CPU#intel-undervolt
