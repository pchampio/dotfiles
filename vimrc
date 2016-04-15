" Leader Mappings
let mapleader = ","


" Add bundles
if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

filetype plugin indent on
set omnifunc=syntaxcomplete#Complete

" Regenerate tags
map <leader>rt :!ctags --extra=+f  --exclude=.git  --exclude=log -R * <CR><C-M>"

" Clipboard
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

" Show command
set showcmd

" highlight vertical column of cursor
au WinLeave * set nocursorline nocursorcolumn
au WinEnter * set cursorline
set cursorline

" Theme
colorscheme solarized
set background=dark

" relativ number
set numberwidth=4
set relativenumber
set number
set timeout ttimeoutlen=50

" -- Beep
set visualbell   " Empeche Vim de beeper
set noerrorbells " Empeche Vim de beeper

" Reduce timeout after <ESC> is recvd. This is only a good idea on fast links.
set ttimeout
set ttimeoutlen=20
set notimeout

" tell it to use an undo file
set undofile
" set a directory to store the undo history
set undodir=~/.vimundo/

set backspace=2  " Backspace deletes like most programs in insert mode
set nobackup     " No *.ext~
set nowritebackup
set noswapfile   " No *.swp
set history=500
set ruler        " show the cursor position all the time
set incsearch    " do incremental searching
set hlsearch     " highlight matches
set autowrite    " Automatically :write before running commands

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab

" Case
set smartcase
set ignorecase
set noantialias

" Display extra whitespace
set nowrap
set list listchars=tab:▸\ ,trail:·,extends:›,precedes:‹
highlight SpecialKey ctermbg=none cterm=none

" UTF-8 power
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

set ttyfast    " u got a fast terminal
set lazyredraw " to avoid scrolling problems

nnoremap <Leader>zz :let &scrolloff=999-&scrolloff<CR>
set so=7


"Improve completion popup menu
"inoremap <expr> <Tab> ((pumvisible())?("\<C-p>"):("\tab>"))
"inoremap <expr> <C-k> ((pumvisible())?("\<C-p>"):("<C-k>"))
"inoremap <expr> <Space>      pumvisible() ? "\<C-y>" : "\<Space>"
"inoremap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"

"map <tab> %

" Enable mouse use in all modes
set mouse=a

" resizing a window split
map <Left> <C-w><
map <Down> <C-W>-
map <Up> <C-W>+
map <Right> <C-w>>

"Easy :noh
map <leader>h :noh<CR>

" searching
noremap n nzz
noremap N Nzz

" don't move on *
noremap * *<c-o>

" Note that remapping C-s requires flow control to be disabled
" (e.g. in .bashrc or .zshrc)
map <C-s> <esc>:w<CR>
imap <C-s> <esc>:w<CR>

" Spell-Checking
" zg add word to the spelling dictionary
" zw remove it
map <silent> <F7> "<Esc>:silent setlocal spell! spelllang=en<CR>"
map <silent> <F6> "<Esc>:silent setlocal spell! spelllang=fr<CR>"

"key to insert mode with paste using F2 key
map <F2> :set paste<CR>i
" Leave paste mode on exit
au InsertLeave * set nopaste

" no more ex Mode
nnoremap Q <nop>

"Moving lines
nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
inoremap <M-j> <Esc>:m .+1<CR>==gi
inoremap <M-k> <Esc>:m .-2<CR>==gi
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv

noremap <F1> <Nop>

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Quicker navigation
noremap H ^
noremap L g_
noremap K 5k
noremap J 5j


" Pipe output of shell command into vim buffer
function! ShellIntoBuff()
    call inputsave()
    let cmd = input('Enter shell cmd: ')
    call inputrestore()
    execute 'new | r !'.cmd.''
endfunction
cnoreabbrev shell call ShellIntoBuff()

" remapping
cnoreabbrev qwa wqa
cnoreabbrev aw wa
cnoreabbrev qw wq
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Qall! qall!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Qall qall

" open file name under cursor create if necessary
nnoremap gf :view <cfile><cr>

" Align blocks of text and keep them selected
vmap < <gv
vmap > >gv

" FileType syntax highlight
au BufNewFile,BufRead *.conf setf ngnix
au BufNewFile,BufReadPost *.md set filetype=markdown

" --------------------------
" function
" --------------------------


" ALT / META KEY on 7bits term
let c='a'
while c <= 'z'
  exec "set <A-".c.">=\e".c
  exec "imap \e".c." <A-".c.">"
  let c = nr2char(1+char2nr(c))
endw
nnoremap <M-c> :echoe "ALT/meta is working !!!"<CR>

" Vim jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal! g'\"" | endif
endif

" Tab completion
" will insert tab at beginning of line,
" will use completion if not at beginning
set wildmode=list:longest,list:full
set complete=.,w,t
function! InsertTabWrapper()
  let col = col('.') - 1
  if !col || getline('.')[col - 1] !~ '\k'
    return "\<tab>"
  else
    return "\<c-p>"
  endif
endfunction
inoremap <Tab> <c-r>=InsertTabWrapper()<cr>

" Call gramamr Plugin
function! Grammar()
call inputsave()
    let lang = input('Enter the lang (fr,en) ')
    call inputrestore()
    execute 'GrammarousCheck --lang='.lang.''
endfunction
nnoremap <Leader>s :call Grammar()<cr>
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en
autocmd FileType gitcommit setlocal spell
noremap <M-s> ei<C-x>s
set spellfile=~/dotfiles/spell/ownSpellFile.utf-8.add

" Remove trailing whitespace on save
function! s:RemoveTrailingWhitespaces()
  "Save last cursor position
  let l = line(".")
  let c = col(".")

  %s/\s\+$//ge

  call cursor(l,c)
endfunction

let blacklist = ['md', 'markdown', 'mrd']
au BufWritePre * if index(blacklist, &ft) < 0 | :call <SID>RemoveTrailingWhitespaces()


" Copied form Steve Losh ->  https://gist.github.com/sjl/1171642
" Motion for "next/last object". For example, "din(" would go to the next "()" pair
" and delete its contents.

onoremap an :<c-u>call <SID>NextTextObject('a', 'f')<cr>
xnoremap an :<c-u>call <SID>NextTextObject('a', 'f')<cr>
onoremap in :<c-u>call <SID>NextTextObject('i', 'f')<cr>
xnoremap in :<c-u>call <SID>NextTextObject('i', 'f')<cr>

onoremap al :<c-u>call <SID>NextTextObject('a', 'F')<cr>
xnoremap al :<c-u>call <SID>NextTextObject('a', 'F')<cr>
onoremap il :<c-u>call <SID>NextTextObject('i', 'F')<cr>
xnoremap il :<c-u>call <SID>NextTextObject('i', 'F')<cr>

function! s:NextTextObject(motion, dir)
  let c = nr2char(getchar())

  if c ==# "b"
      let c = "("
  elseif c ==# "B"
      let c = "{"
  elseif c ==# "d"
      let c = "["
  endif

  exe "normal! ".a:dir.c."v".a:motion.c
endfunction
