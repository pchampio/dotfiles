" Leader Mappings
let mapleader = ","

" Add bundles
set nocompatible

call plug#begin('~/.vim/autoload')

Plug 'tpope/vim-sensible'

" -------------------
" A collection of +70 language packs for Vim
" -------------------
Plug 'sheerun/vim-polyglot'
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
let g:markdown_fenced_languages = ["ruby", "C=c", "c", "bash=sh", "sh", "html", "css", "vim", "python"]

" -------------------
" leader m to expand a split
" -------------------
Plug 'blarghmatey/split-expander'

" -------------------
" A Vim plugin which shows a git diff in the numberline
" -------------------
Plug 'airblade/vim-gitgutter'
let g:gitgutter_map_keys = 0

" Insert or delete brackets
Plug 'jiangmiao/auto-pairs'

" -------------------
" . command after a plugin map
" -------------------
Plug 'tpope/vim-repeat'

" -------------------
" change surround cs"'
" -------------------
Plug 'tpope/vim-surround'

" -------------------
" https://languagetool.org/fr/
" -------------------
Plug 'rhysd/vim-grammarous'
let g:grammarous#hooks = {}
function! g:grammarous#hooks.on_check(errs)
    nmap <buffer><C-n> <Plug>(grammarous-move-to-next-error)
    nmap <buffer><C-p> <Plug>(grammarous-move-to-previous-error)
endfunction

function! g:grammarous#hooks.on_reset(errs)
    nunmap <buffer><C-n>
    nunmap <buffer><C-p>
endfunction

" -------------------
" Replace + motion
" -------------------
Plug 'vim-scripts/ReplaceWithRegister'
" gr replace motion

" -------------------
" Aligning text
" -------------------
Plug 'junegunn/vim-easy-align'
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" -------------------
" Always highlight enclosing tags
" -------------------
Plug 'Valloric/MatchTagAlways'

" -------------------
" Commanter
" -------------------
Plug 'scrooloose/nerdcommenter'
let NERDUsePlaceHolders=0
let NERDSpaceDelims=1
let g:NERDCustomDelimiters = {
    \ 'c': { 'left' : '//', 'leftAlt' : '/*', 'rightAlt': '*/' }
\ }

" -------------------
" NERDTree
" -------------------
" git status flags
Plug 'Xuyuanp/nerdtree-git-plugin', { 'on':  [ 'NERDTreeToggle' , 'NERDTreeFind'] }
Plug 'scrooloose/nerdtree', { 'on':  [ 'NERDTreeToggle' , 'NERDTreeFind'] }
map <leader>n :NERDTreeToggle<CR>
map <leader>k :NERDTreeFind<cr>
let NERDTreeMapActivateNode='<space>'
let NERDTreeMapOpenInTab='<ENTER>'
let NERDTreeIgnore = ['\.pyc$','\.o$', '\~$', '\.db$', '\.sqlite$', '__pycache__']
let NERDTreeShowHidden=1

" icons need to patch fonts
Plug 'ryanoasis/vim-devicons', { 'on':  [ 'NERDTreeToggle' , 'NERDTreeFind'] }
" let g:WebDevIconsUnicodeDecorateFolderNodes = 1
" let g:WebDevIconsUnicodeGlyphDoubleWidth = 0

" -------------------
" syntastic
" -------------------
Plug 'scrooloose/syntastic'

" configure syntastic syntax checking to check on open as well as save
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_loc_list_height=5

" -------------------
" THEME-SYNTAX
" -------------------
"Plug 'altercation/vim-colors-solarized'
Plug 'morhetz/gruvbox'
let g:gruvbox_contrast_dark="medium"
let g:gruvbox_contrast_light="medium"

let g:gruvbox_sign_column="dark0"
let g:gruvbox_color_column="dark0"
let g:gruvbox_vert_split="dark0"

" tmux-navigator configuration
Plug 'christoomey/vim-tmux-navigator'

" -------------------
" tabline for vim (powerline)
" -------------------
Plug 'bling/vim-airline'
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline_symbols.space="\ua0"
let g:airline_theme='gruvbox'
set t_Co=256
let &t_EI = "\<Esc>[2 q"

au BufNewFile,BufRead *.md silent call airline#extensions#whitespace#toggle()

" Set cursor to vertical line when in insert mode.
if exists('$TMUX')
  let &t_SI="\ePtmux;\e\e[6 q\e\\"
  let &t_EI="\ePtmux;\e\e[2 q\e\\"
endif
set guicursor=a:blinkon0

" -------------------
" <leader>u for git like undo
" -------------------
Plug 'mbbill/undotree', { 'on': 'UndotreeToggle' }
nnoremap <leader>u :UndotreeToggle<cr>
let g:undotree_WindowLayout = 2

" TAGS
" install exuberant-ctags
Plug 'majutsushi/tagbar'
nmap <leader>t :TagbarToggle<CR>
let g:tagbar_compact = 1



" -------------------
" AUTO-complete
" -------------------

" Plug 'ajh17/VimCompletesMe'
" let g:vcm_direction = 'n'
" let b:vcm_tab_complete = 'tags'

" OR

Plug 'Shougo/neocomplete.vim'
let g:acp_enableAtStartup = 0
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#auto_completion_start_length = 1
let g:neocomplete#enable_fuzzy_completion = 1
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"

" -------------------
"  Snippets
" -------------------
Plug 'SirVer/ultisnips'

" Snippets are separated from the engine.
Plug 'honza/vim-snippets'

" 'SirVer/ultisnips' options.
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger  = "<leader><TAB>"

" Enable heavy omni completion.
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

let g:simpledb_show_timing = 0
Plug 'ivalkeen/vim-simpledb'
Plug 'krisajenkins/vim-postgresql-syntax'

" ----------------------------- END -----------------------------
call plug#end()

" Theme
colorscheme gruvbox
set background=dark

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

filetype plugin indent on

" Regenerate tags
noremap <leader>rt :!ctags --extra=+f --exclude=.git --exclude=log -R * <CR><C-M>

" Clipboard
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

" Show command
set showcmd

set laststatus=2 " Always display the statusline in all windows
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)

" highlight vertical column of cursor
au WinLeave * set nocursorline nocursorcolumn
au WinEnter * set cursorline
set cursorline

" 90 columns
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%91v.\+/

" relativ number
set numberwidth=4
set relativenumber
set number

" -- Beep
set visualbell   " Empeche Vim de beeper
set noerrorbells " Empeche Vim de beeper

" Reduce timeout after <ESC> is recvd. This is only a good idea on fast links.
set ttimeout
set ttimeoutlen=50
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
set showmatch    "  Highlight matching brace

" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab

" Case
set smartcase
set ignorecase

" Display extra whitespace
set sidescroll=1
set nowrap
set list listchars=tab:▸\ ,trail:·,extends:›,precedes:‹
highlight SpecialKey ctermbg=none cterm=none

" UTF-8 power
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set fileformat=unix

set spellfile=~/dotfiles/spell/ownSpellFile.utf-8.add

set ttyfast    " u got a fast terminal
set lazyredraw " to avoid scrolling problems
set fillchars=vert:\|

nnoremap <Leader>zz :let &scrolloff=999-&scrolloff<CR>
set so=7

" Enable mouse use in all modes
set mouse=a

" Open vimrc in new tab
map <leader>vim :tabe ~/.vimrc<cr>

" To make vsplit put the new buffer on the right/below of the current buffer:
set splitbelow
set splitright

" resizing a window split
map <Left> <C-w><
map <Down> <C-W>-
map <Up> <C-W>+
map <Right> <C-w>>

"Easy :noh
map <leader>h :noh<cr>

" Sudo save
cmap w!! w !sudo tee > /dev/null %

" Insert New line
noremap U o<ESC>

" searching
noremap n nzz
noremap N Nzz

" don't move on *
noremap * *<c-o>

" Note that remapping C-s requires flow control to be disabled
" (e.g. in .bashrc or .zshrc)
map <C-s> <esc>:w!<CR>
imap <C-s> <esc>:w!<CR>

" Spell-Checking
" zg add word to the spelling dictionary
" zw remove it
map <silent> <F7> "<Esc>:silent setlocal spell! spelllang=en<CR>"
map <silent> <F6> "<Esc>:silent setlocal spell! spelllang=fr<CR>"

" no morennoremap Q <nop>ex Mode
nnoremap Q <nop>

" use space for moving to the newt word
noremap <space> 2w

" ALT Mappings (Macro conflict)
execute "set <M-k>=\ek"
execute "set <M-j>=\ej"
execute "set <M-s>=\es"

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
cnoreabbrev qw wq
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev qq q

" open file name under cursor create if necessary
nnoremap gf :view <cfile><cr>

" Align blocks of text and keep them selected
vmap < <gv
vmap > >gv

" FileType syntax highlight
au BufNewFile,BufRead *.conf setf ngnix

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" --------------------------
" function
" --------------------------

" Vim jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal! g'\"" | endif
endif

" Call gramamr Plugin
function! Grammar()
call inputsave()
    let lang = input('Enter the lang (fr,en) ')
    if(empty(lang)) | return | endif
    call inputrestore()
    execute 'GrammarousCheck --lang='.lang.''
endfunction

nnoremap <Leader><Leader>s :call Grammar()<cr>
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en
autocmd FileType gitcommit setlocal spell
noremap <silent> <M-s> ei<C-x>s

" Remove trailing whitespace on save
function! s:RemoveTrailingWhitespaces()
  "Save last cursor position
  let l = line(".")
  let c = col(".")
  %s/\s\+$//ge
  call cursor(l,c)
endfunction

let blacklist = ['md', 'markdown', 'mrd', 'markdown.pandoc']
au BufWritePre * if index(blacklist, &ft) < 0 | :call <SID>RemoveTrailingWhitespaces()

" This allows you to visually select a section and then hit @ to run a macro on all lines.
" Prevent the collision between escape and alt
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! ExecuteMacroOverVisualRange()
  execute "nnoremap @ @"
  execute "set <M-k>="
  execute "set <M-j>="
  execute "set <M-s>="
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
  execute "set <M-k>=\ek"
  execute "set <M-j>=\ej"
  execute "set <M-s>=\es"
  execute "nnoremap @ v:<C-u>call ExecuteMacroOverVisualRange()<CR>"
endfunction
nnoremap @ v:<C-u>call ExecuteMacroOverVisualRange()<CR>

"Moving lines
nnoremap <M-j> :m .+1<CR>==
nnoremap <M-k> :m .-2<CR>==
vnoremap <M-j> :m '>+1<CR>gv=gv
vnoremap <M-k> :m '<-2<CR>gv=gv
