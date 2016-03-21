" ALT / META KEY on 7bits term
let c='a'
while c <= 'z'
  exec "set <A-".c.">=\e".c
  exec "imap \e".c." <A-".c.">"
  let c = nr2char(1+char2nr(c))
endw

" relativ number
set relativenumber

set timeout ttimeoutlen=50
nnoremap <M-c> :echoe "ALT/meta is working !!!"<CR>

" resizing a window split
map <Left> <C-w><
map <Down> <C-W>-
map <Up> <C-W>+
map <Right> <C-w>>

" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<ENTER>"
let g:UltiSnipsJumpBackwardTrigger="<c-q>"

" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" Gundo key
nnoremap <F5> :GundoToggle<CR>
let g:gundo_width = 50

" tell it to use an undo file
set undofile
" set a directory to store the undo history
set undodir=~/.vimundo/

" no more ex Mode
nnoremap Q <nop>

nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
inoremap <M-j> <Esc>:m .+1<CR>==gi
inoremap <M-k> <Esc>:m .-2<CR>==gi
vnorema <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv

" Clipboard
set clipboard=unnamedplus

" Leader Mappings
let mapleader = ","

" Toggle nerdtree
map <leader>n :NERDTreeToggle<CR>
map <leader>k :NERDTreeFind<cr>

let NERDTreeMapActivateNode='<space>'
let NERDTreeMapOpenInTab='<ENTER>'
let NERDTreeIgnore = ['\.pyc$','\.o$']

" Note that remapping C-s requires flow control to be disabled
" (e.g. in .bashrc or .zshrc)
map <C-s> <esc>:w<CR>
imap <C-s> <esc>:w<CR>

" -- Beep
set visualbell " Empeche Vim de beeper
set noerrorbells " Empeche Vim de beeper


" Reduce timeout after <ESC> is recvd. This is only a good idea on fast links.
set ttimeout
set ttimeoutlen=20
set notimeout

" add bundles
if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

" Edit another file in the same directory as the current file
" uses expression to extract path from current file's path

" highlight vertical column of cursor
au WinLeave * set nocursorline nocursorcolumn
au WinEnter * set cursorline
set cursorline

"key to insert mode with paste using F2 key
map <F2> :set paste<CR>i
" Leave paste mode on exit
au InsertLeave * set nopaste

set backspace=2   " Backspace deletes like most programs in insert mode
set nocompatible  " Use Vim settings, rather then Vi settings
set nobackup
set nowritebackup
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set history=500
set ruler         " show the cursor position all the time
set incsearch     " do incremental searching
set hlsearch      " highlight matches
set laststatus=2  " Always display the status line
set autowrite     " Automatically :write before running commands


filetype plugin indent on

" bind K to search word under cursor
nnoremap K :Ag "\b<C-R><C-W>\b"<CR>:cw<CR>

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab

" Display extra whitespace
set list listchars=tab:»·,trail:·


" Airline
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline_theme='solarized'
set t_Co=256

:set smartcase
:set ignorecase
:set noantialias

" Color scheme
colorscheme solarized
set background=dark
set encoding=utf-8

" Highlight line number of where cursor currently is
hi CursorLineNr guifg=#050505

" Numbers
set number
set numberwidth=4

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" configure syntastic syntax checking to check on open as well as save
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_loc_list_height=5

" Remove trailing whitespace on save
function! s:RemoveTrailingWhitespaces()
  "Save last cursor position
  let l = line(".")
  let c = col(".")

  %s/\s\+$//ge

  call cursor(l,c)
endfunction

au BufWritePre * :call <SID>RemoveTrailingWhitespaces()

" Enable mouse use in all modes
set mouse=a
