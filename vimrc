set nocompatible
runtime! macros/matchit.vim

" ssh
let g:remoteSession = ($SSH_CONNECTION != "")

autocmd StdinReadPre * let g:isReadingFromStdin = 1

let $SHELL='/bin/zsh'

" ALT keys Mappings
function! Altmap(char)
  if has('gui_running') | return ' <A-'.a:char.'> ' | else | return ' <Esc>'.a:char.' '|endif
endfunction

filetype plugin indent on
syntax enable

" Leader Mappings
let mapleader = ","

" Add bundles
call plug#begin('~/.vim/bundle/')

" Plug 'KabbAmine/vCoolor.vim'
" let g:vcoolor_map = '<c-b>'

Plug 'machakann/vim-highlightedyank'
map y <Plug>(highlightedyank)
hi! link HighlightedyankRegion SpellRare

" Plug 'gorodinskiy/vim-coloresque'

" searching
Plug 'wincent/scalpel'
Plug 'wincent/loupe'
let g:LoupeHighlightGroup='IncSearch'
map <leader><space> <Plug>(LoupeClearHighlight)
let g:LoupeCenterResults=0
let g:LoupeHighlightGroup='IncSearch'
nmap <Nop> <Plug>(LoupeStar)

if !has("gui_running")
  augroup map_search
      autocmd!
      au VimEnter * nmap <silent> * *``zz
      au VimEnter * hi! link Search SpellRare
  augroup END
end

nnoremap g/ :Ack<space>


Plug 'wincent/ferret'
let g:FerretMap=0
nmap <leader>* <Plug>(FerretAckWord)
nnoremap <c-n> :cnf<cr>
nnoremap <c-b> :cpf<cr>
nmap <leader>E <Plug>(FerretAcks)

" enhances Vim's integration with the terminal
Plug 'wincent/terminus'

" Git Plug.vim (lazy)
Plug 'lambdalisue/gina.vim', {'on': ['Gina']}
nnoremap <leader>gs :Gina status
set diffopt=vertical

Plug 'pseewald/vim-anyfold'
nnoremap <space> za
let anyfold_activate=1
set foldlevel=20

 " Ctrl-P FuzzyFinder

Plug 'ctrlpvim/ctrlp.vim'
" let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_map='<c-p>'
" let g:ctrlp_lazy_update = 1
" let g:ctrlp_dotfiles = 1
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("v")': ['<c-v>', '<RightMouse>', '<c-s>'],
    \ 'AcceptSelection("h")': ['<c-x>', '<c-cr>', '<c-i>'],
    \ 'PrtCurStart()':        ['<space>', '<c-a>'],
\ }

if executable('ag')
"sudo apt-get install silversearcher-ag
  set grepprg=ag\ --nogroup\ --nocolor
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
  let g:ctrlp_use_caching = 0
endif
if executable('rg')
  set grepprg=rg\ --color=never
  let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
  let g:ctrlp_use_caching = 0
endif
nnoremap \ :CtrlPLine<cr>
nnoremap <c-t> :CtrlPTag<cr>

let g:ctrlp_abbrev = {
    \ 'gmode': 't',
    \ 'abbrevs': [
        \ {
        \ 'pattern': ';',
        \ 'expanded': ':',
        \ 'mode': 'pfrz',
        \ },
        \ ]
    \ }

" let g:ctrlp_buffer_func = { 'exit':  'CtrlpExit', }
" function CtrlpExit()
  " set cursorline
" endfunction

let g:ctrlp_default_input = 1
autocmd VimEnter * if (argc() && isdirectory(argv()[0]) || !argc()) && !exists('g:isReadingFromStdin') | execute' CtrlP' | endif

" define in autoload
let g:ctrlp_status_func = {
  \ 'main': 'CtrlP_main_status',
  \ 'prog': 'CtrlP_progress_status'
  \}

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" A collection of +70 language packs for Vim
Plug 'sheerun/vim-polyglot'
let g:polyglot_disabled = ['javascript', 'python']
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
let g:markdown_fenced_languages = ["ruby", "C=c", "c", "bash=sh",
      \ "sh", "html", "css", "vim", "python", "javascript"]

Plug 'hdima/python-syntax'
let python_highlight_all = 1

Plug 'slashmili/alchemist.vim'
" https://asciinema.org/a/f32bc29pky7s9eqkyjmb33gia
let g:alchemist#elixir_erlang_src = "/usr/local/share/src/"
let g:alchemist_tag_map = '<Leader>g'

" scala
Plug 'ensime/ensime-vim'

autocmd FileType scala,java
      \ nnoremap <buffer> <silent> <leader>t :EnType<CR> |
      \ xnoremap <buffer> <silent> <leader>t :EnType selection<CR> |
      \ nnoremap <buffer> <silent> <leader>T :EnTypeCheck<CR> |
      \ nnoremap <buffer> <silent> <C-]>  :EnDeclaration<CR> |
      \ nnoremap <buffer> <silent> <leader>g  :EnDeclaration<CR> |
      \ nnoremap <buffer> <silent> <leader>G :EnDeclarationSplit v<CR> |
      \ nnoremap <buffer> <silent> <leader>I :EnSuggestImport<CR>


Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
autocmd FileType go nnoremap <Leader>g :GoDef<cr>
autocmd FileType go nnoremap <Leader>G :vsp <cr> :GoDef<cr>

" use goimports for formatting
let g:go_fmt_command = "goimports"

" turn highlighting on
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_structs = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_types = 1
let g:go_highlight_extra_types = 1

Plug 'othree/javascript-libraries-syntax.vim'

Plug 'adimit/prolog.vim'
autocmd FileType prolog :nnoremap <buffer> <silent> <cr> :execute "normal vip\<Plug>NERDCommenterToggle"<cr>
      \ :VtrOpenRunner {'orientation': 'h', 'percentage': 30, 'cmd': 'swipl'}<cr>
      \ :VtrSendCommand! abort. %; swipl<cr>
      \ :VtrSendCommand! [<c-r>=expand('%:r')<cr>].<cr> vip:VtrSendLinesToRunner<cr>
      \ :undo<cr>

autocmd FileType jess :nnoremap <buffer> <silent> <cr>
      \ :VtrOpenRunner {'orientation': 'h', 'percentage': 30, 'cmd': 'clips'}<cr>
      \ :VtrSendCommand! (clear) ; clips<cr>
      \ :VtrSendCommand! (load <c-r>=expand('%:t')<cr>)<cr>
      \ :VtrSendCommand! (reset)<cr>
      \ :VtrSendCommand! (run)<cr>

autocmd FileType jess :nnoremap <buffer> <silent> <Leader>e
      \ :VtrSendCommand! (exit)<cr>

autocmd FileType jess :nnoremap <buffer> <silent> <Leader>f
      \ :VtrSendCommand! (facts)<cr>

Plug 'othree/yajs.vim'
" Plug 'lepture/vim-jinja'
Plug 'zsiciarz/caddy.vim'


" end Syntax

" A Vim plugin which shows a git diff in the numberline
Plug 'mhinz/vim-signify'
let g:signify_sign_change = '~'
nmap <leader>gj <plug>(signify-next-hunk)
nmap <leader>gk <plug>(signify-prev-hunk)

" Insert or delete brackets
Plug 'cohama/lexima.vim'
nnoremap <leader>p :let b:lexima_disabled=1<CR>

" surround
Plug 'machakann/vim-sandwich'
xmap is <Plug>(textobj-sandwich-query-i)
xmap as <Plug>(textobj-sandwich-query-a)
omap is <Plug>(textobj-sandwich-query-i)
omap as <Plug>(textobj-sandwich-query-a)

xmap ii <Plug>(textobj-sandwich-auto-i)
xmap ai <Plug>(textobj-sandwich-auto-a)
omap ii <Plug>(textobj-sandwich-auto-i)
omap ai <Plug>(textobj-sandwich-auto-a)

xmap in <Plug>(textobj-sandwich-literal-query-i)
xmap an <Plug>(textobj-sandwich-literal-query-a)
omap in <Plug>(textobj-sandwich-literal-query-i)
omap an <Plug>(textobj-sandwich-literal-query-a)

" https://languagetool.org/fr/
Plug 'rhysd/vim-grammarous'
let g:grammarous#jar_url = 'https://www.languagetool.org/download/LanguageTool-3.3.zip'
let g:grammarous#hooks = {}
function! g:grammarous#hooks.on_check(errs)
    nmap <buffer><C-n> <Plug>(grammarous-move-to-next-error)
    nmap <buffer><C-p> <Plug>(grammarous-move-to-previous-error)
endfunction

function! g:grammarous#hooks.on_reset(errs)
    nunmap <buffer><C-n>
    nunmap <buffer><C-p>
endfunction

function! GetLang() " return lang
  call inputsave()
  let lang = input('Enter the lang (fr,en) ')
  if(empty(lang)) | return | endif
  call inputrestore()
  return lang
endfunction

function! Comments() " comment or not
  call inputsave()
  let chr = input('Comments Only (y,n) ')
  call inputrestore()
  if chr == 'y'
    return "--comments-only"
  else
    return "--no-comments-only"
  endif
endfunction

nnoremap <leader>R :GrammarousReset<cr>
nnoremap <Leader>S :GrammarousCheck
      \ --lang=<c-r>=GetLang()<cr> <c-r>=Comments()<cr><cr>

vnoremap <Leader>S :'<,'> GrammarousCheck
      \ --lang=<c-r>=GetLang()<cr> <c-r>=Comments()<cr><cr>

vnoremap <silent><expr>  ++  VMATH_YankAndAnalyse()
nnoremap <silent>        ++  vip++

" Replace + motion
Plug 'vim-scripts/ReplaceWithRegister'
" gr replace motion
nmap r  <Plug>ReplaceWithRegisterOperator
nmap rr <Plug>ReplaceWithRegisterLine
xmap r  <Plug>ReplaceWithRegisterVisual

noremap R r

" Aligning text
Plug 'junegunn/vim-easy-align'
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" Always highlight enclosing tags HTML XML
Plug 'Valloric/MatchTagAlways'

" simplifies the transition between multiline and single-lin
Plug 'AndrewRadev/splitjoin.vim'

" move function arguments
Plug 'AndrewRadev/sideways.vim'

execute 'nnoremap'.Altmap('.').":SidewaysRight<cr>"
execute 'nnoremap'.Altmap(',').":SidewaysLeft<cr>"
" nnoremap <c-h> :SidewaysLeft<cr>
" nnoremap <c-l> :SidewaysRight<cr>

"argument text object.
omap aa <Plug>SidewaysArgumentTextobjA
xmap aa <Plug>SidewaysArgumentTextobjA
omap ia <Plug>SidewaysArgumentTextobjI
xmap ia <Plug>SidewaysArgumentTextobjI

if !g:remoteSession
  Plug 'ludovicchabant/vim-gutentags'
  " Exclude css, html, js files from generating tag files
  " let g:gutentags_exclude = ['*.css', '*.html', '*.js']
  " Where to store tag files
  let g:gutentags_cache_dir = '~/.vim/gutentags'
  let g:gutentags_project_root = ['.git', 'Makefile', 'makefile', 'Gemfile']
  noremap <leader>rt :GutentagsUpdate<cr>:redraw!<cr>
endif

" gem install ripper-tags
 " let g:gutentags_ctags_executable_ruby = 'ripper-tags -R --exclude=vendor'

Plug 'rhysd/clever-f.vim'
let g:clever_f_chars_match_any_signs = ';'
" let g:clever_f_mark_char_color = 'SpellRare'

" Commanter
Plug 'scrooloose/nerdcommenter'
let NERDUsePlaceHolders=0
let NERDSpaceDelims=1
let g:NERDCustomDelimiters = {
    \ 'c': { 'left' : '//', 'leftAlt' : '/*', 'rightAlt': '*/' },
    \ 'javascript.jsx': { 'left' : '//', 'leftAlt' : '/*', 'rightAlt': '*/' },
    \ 'caddy': { 'left' : '#' },
\ }

" syntastic
Plug 'w0rp/ale'
let g:ale_lint_on_text_changed = 'never'
let g:ale_list_window_size = 5

let g:ale_lint_on_enter = 0
let g:ale_open_list = 1

nnoremap <leader>dd :ALEDisable<CR>

hi! link ALEErrorSign SpellBad
hi! link ALEWarningSign SpellRare

" THEME-SYNTAX
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-solarized8'
let g:gruvbox_contrast_dark="medium"
let g:gruvbox_contrast_light="soft"

" let g:gruvbox_sign_column="dark0"
" let g:gruvbox_vert_split="dark0"

Plug 'kristijanhusak/vim-hybrid-material'
let g:enable_bold_font = 1

" Plug 'Yggdroot/indentLine'
" let g:indentLine_char = ''

" tmux-navigator configuration
Plug 'christoomey/vim-tmux-navigator'

" <leader>u for git like undo
Plug 'simnalamburt/vim-mundo'
nnoremap <leader>u :MundoToggle<CR>
let g:mundo_width=70
let g:mundo_playback_delay=40
let g:mundo_verbose_graph=0

inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
inoremap <expr><leader><leader>  pumvisible() ? "\<C-y>" : "\<esc>:w\<cr>"

if !g:remoteSession
  if !has('nvim')
    Plug 'Shougo/neocomplete.vim'
    " Plug 'wellle/tmux-complete.vim'
    let g:neocomplete#enable_at_startup = 1
    let g:neocomplete#enable_smart_case = 1
    let g:neocomplete#auto_completion_start_length = 2
    let g:neocomplete#enable_fuzzy_completion = 1
    " User must pause before completions are shown.
    " https://www.reddit.com/r/vim/comments/2xl33m
    let g:neocomplete#enable_cursor_hold_i = 1
    let g:neocomplete#cursor_hold_i_time = 500 " milliseconds
    if !exists('g:neocomplete#force_omni_input_patterns')
      let g:neocomplete#force_omni_input_patterns = {}
    endif

          " \ "ruby" : '([^:][^:][^:][^:][^:][^:][^:][^:][^:][^:][^:])([^. *\t:])\.\w*',
    let g:neocomplete#sources#omni#input_patterns = {
          \ "scala" : '\k\.\k*',
          \ "ruby" : '[^. *\t]\.\w*\|\h\w*::',
          \ "c" : '[^.[:digit:] *\t]\%(\.\|->\)\%(\h\w*\)\?',
          \ "cpp" : '[^.[:digit:] *\t]\%(\.\|->\)\w*\|\h\w*::\w*',
          \ "python" : '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*',
          \}
  else
    Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }

    " Required for operations modifying multiple buffers like rename.
    set hidden

    " Use deoplete.
    Plug 'Shougo/deoplete.nvim'
    let g:deoplete#enable_at_startup = 1

    Plug 'zchee/deoplete-jedi'

  endif
else
  Plug 'ajh17/VimCompletesMe'
  let g:vcm_direction = 'n'
  let b:vcm_tab_complete = 'tags'
endif

" Plug 'roxma/nvim-completion-manager'

set complete=i,.,b,w,u,U,]

Plug 'vim-ruby/vim-ruby'
" autocmd FileType ruby compiler ruby
let g:rubycomplete_buffer_loading = 1
let g:rubycomplete_classes_in_global = 1
" let g:rubycomplete_rails = 1
let g:rubycomplete_load_gemfile = 1
" let g:rubycomplete_gemfile_path = 'Gemfile.aux'
Plug 'tpope/vim-rails'
augroup Project
  autocmd!

  " Snippets
  autocmd FileType ruby  set filetype=rails.ruby
  autocmd FileType erb   set filetype=rails.erb
  autocmd FileType rspec set filetype=rails.rspec.ruby
augroup END

set completeopt-=preview

Plug 'tweekmonster/braceless.vim'
autocmd FileType python BracelessEnable +indent

Plug 'tweekmonster/django-plus.vim'

Plug 'davidhalter/jedi-vim'
let g:jedi#documentation_command = ""
let g:jedi#usages_command = "<leader>N"
let g:jedi#goto_definitions_command = "<leader>g"
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#smart_auto_mappings = 0

let g:jedi#force_py_version = 3


Plug 'justmao945/vim-clang' " need clang installed
" disable auto completion for vim-clang
let g:clang_auto = 0
" default 'longest' can not work with neocomplete
let g:clang_c_completeopt = 'menuone'
let g:clang_cpp_completeopt = 'menuone'


" Enable omni completion.
augroup COMPLETE
  autocmd!
  autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType python setlocal omnifunc=jedi#completions
  autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
augroup end

"  Snippets
Plug 'SirVer/ultisnips'

" Snippets are separated from the engine.
Plug 'honza/vim-snippets'
" let g:UltiSnipsSnippetsDir="~/.vim/bundle/vim-snippets/"
let g:UltiSnipsSnippetDirectories=[$HOME.'/dotfiles/snippets', 'snips', 'UltiSnips']


" 'SirVer/ultisnips' options.
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger  = "<leader><leader>"

Plug 'christoomey/vim-tmux-runner'
autocmd FileType sh,bash,zsh :nnoremap <cr> mavip:VtrSendLinesToRunner<cr>`a


" ----------------------------- END -----------------------------
call plug#end()

" 80 columns
set colorcolumn=80      " highlight the 80 column
set synmaxcol=190         " limit syntax Highlighting

" set autoread " disable 'read-only to writeable' warnings
autocmd FileChangedShell * echohl WarningMsg | echo "File changed shell." | echohl None

" Theme
colorscheme gruvbox
" colorscheme hybrid_material
set background=dark
set background=light

"  256 colors
set t_Co=256

" Highlight VCS conflict markers
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

set wildignore+=.hg,.git,.svn                           " Version control
set wildignore+=*.aux,*.out,*.toc                       " LaTeX intermediate files
" set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg          " binary images
set wildignore+=*.luac                                  " Lua byte code
set wildignore+=*.o,*.lo,*.obj,*.exe,*.dll,*.manifest   " compiled object files
set wildignore+=*.pyc                                   " Python byte code
set wildignore+=*.spl                                   " compiled spelling word lists
set wildignore+=*.sw?                                   " Vim swap files
set wildignore+=*~,*.swp,*.tmp                          " Swp and tmp files
set wildignore+=*.DS_Store?                             " OSX bullshit
set wildignore+=*.sqlite3

" Clipboard
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

" Show command
set showcmd
set virtualedit=block

" lightline powerline status
set laststatus=2 " Always display the statusline in all windows

" highlight vertical column of cursor
set cursorline

" relativ number
set numberwidth=4
set relativenumber
set number

" -- Beep
set visualbell   " Empeche Vim de beeper
set noerrorbells " Empeche Vim de beeper

" tell it to use an undo file
set undofile
" set a directory to store the undo history
set undodir=~/.vimundo/


set backspace=2  " Backspace deletes like most programs in insert mode
set nobackup     " No *.ext~
set nowritebackup
set noswapfile   " No *.swp
set history=10000
set incsearch    " do incremental searching
set hlsearch     " highlight matches
set autowrite    " Automatically :write before running commands
set showmatch    "  Highlight matching brace
set autoindent   " maintain indent of current line
set hidden

" Softtabs, 2 spaces tabs
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" Case
set smartcase
set ignorecase

" command autocomplet list
set wildmenu
set wildchar=<Tab>
set wildmode=full

" UTF-8
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set fileformat=unix

" Display extra whitespace
set sidescroll=1
set nowrap
" set list listchars=tab:▸\ ,trail:·,extends:›,precedes:‹
set list listchars=tab:\ \ ,trail:·,extends:›,precedes:‹
highlight SpecialKey ctermbg=none cterm=none

set spellfile=~/dotfiles/spell/ownSpellFile.utf-8.add

set ttyfast    " u got a fast terminal
set lazyredraw
set fillchars=vert:\|

nnoremap <Leader>zz :let &scrolloff=999-&scrolloff<CR>
set sidescrolloff=4
set scrolloff=4

set nojoinspaces
if v:version > 703 " join 2 commants = 1 def comment
  set formatoptions+=j
endif

" Enable mouse use in all modes
set mouse=a

" Open vimrc in new tab
noremap <leader>vi :tabe ~/.vimrc<cr>
" Open vim help on the left of the screen
autocmd FileType help wincmd L

" To make vsplit put the new buffer on the right/below of the current buffer:
set splitbelow
set splitright

" resizing a window split
nnoremap <Left> <C-w>10<
nnoremap <Down> <C-W>5-
nnoremap <Up> <C-W>5+
nnoremap <Right> <C-w>10>

" TIME Out len
set timeoutlen=300 ttimeoutlen=0

" spell
execute 'nnoremap'.Altmap('s')."w[sei<c-x>s"

"Moving lines
execute 'nnoremap'.Altmap('k').":m .-2<CR>=="
execute 'nnoremap'.Altmap('j').":m .+1<CR>=="
execute "vnoremap <up> :m '<-2<CR>gv=gv"
execute "vnoremap <Down> :m '>+1<CR>gv=gv"

" Quicker navigation
noremap H 0^
xmap H ^
omap H ^
noremap L g_

" to null register
" nnoremap d "_d
" nnoremap D "_D

nnoremap c "_c
nnoremap C "_C

noremap <silent> J :call MatchitDOWN()<cr>
function! MatchitDOWN()
  let l:startline=line(".")
  normal %
  if line(".") < l:startline
    :keepjumps normal }j
  endif
  if line(".") <= l:startline
    normal $%
  endif
  if line(".") <= l:startline
    normal ^%
  endif
  if line(".") <= l:startline
    :keepjumps normal }
  endif
endfunction
noremap <silent> K :call MatchitUP()<cr>
function! MatchitUP()
  let l:startline=line(".")
  normal %
  if line(".") > l:startline
    :keepjumps normal {k
  endif
  if line(".") >= l:startline
    normal $%
  endif
  if line(".") >= l:startline
    normal ^%
  endif
  if line(".") >= l:startline
    :keepjumps normal {
  endif
endfunction

noremap <leader>g <c-]>
noremap <Leader>G :vsp <cr> <c-]>
nnoremap <leader><leader> :w!<cr>

nnoremap <Leader>D yyp

vnoremap J }
vnoremap K {
noremap j gj
noremap k gk

inoremap ;; <esc>A;<esc>
inoremap <c-l> <esc>A

" Switch CMD to the dir of the open buffer
noremap <leader>cd :lcd <c-r>=expand("%:p:h")<cr>

" Sudo save
cnoreabbrev <silent> w!! call SudoSave()
function! SudoSave()
  cnoreabbrev q q!
  cabbrev <silent> w call SudoSave()
  cabbrev <silent> wq w call SudoSave()
  execute ":w !sudo tee > /dev/null %"
endfunction

" Insert New line
noremap U :call append(line('.'), '')<CR>j

" Perfect tag closer (xml)
inoremap </ </<C-x><C-o>

" Spell-Checking
" zg add word to the spelling dictionary
" zw remove it
nnoremap <silent> <leader>en <Esc>:silent setlocal spell! spelllang=en<CR>
nnoremap <silent> <leader>fr <Esc>:silent setlocal spell! spelllang=fr<CR>
nnoremap <silent> <leader>all <Esc>:silent setlocal spell! spelllang=fr,en<CR>
nnoremap <silent> <leader>a <Esc>zg
nnoremap <silent> <leader>d <Esc>zug
inoremap <leader>a à
inoremap <leader>u ù
inoremap <c-u> ȗ
inoremap <leader>e é
inoremap <c-e> è
hi clear SpellBad
hi clear SpellRare
hi clear SpellLocal
hi SpellBad   cterm=underline ctermfg=9  ctermbg=0 gui=undercurl
hi SpellCap   cterm=underline ctermfg=14 ctermbg=0 gui=undercurl
hi SpellRare  cterm=underline ctermfg=13 ctermbg=0 gui=undercurl
hi SpellLocal cterm=underline ctermfg=11 ctermbg=0 gui=undercurl

autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en tw=80
autocmd FileType gitcommit setlocal spell spelllang=fr,en
autocmd FileType svn setlocal spell spelllang=fr,en

" no more ex Mode
nnoremap Q <nop>

" remapping
cnoreabbrev qwa wqa
cnoreabbrev qw wq
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev aq qa
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev qq q

nnoremap ; :
nnoremap : ;
vnoremap ; :
vnoremap : ;
cnoreabbrev ; :
cnoreabbrev : ;

" open file name under cursor create if necessary
nnoremap gf :view <cfile><cr>

" --------------------------
" function
" --------------------------
" Go to the last known cursor position in a file
autocmd BufReadPost *
    \ if !(bufname("%") =~ '\(COMMIT_EDITMSG\)') &&
    \   line("'\"") > 1 && line("'\"") < line("$") && &filetype != "svn" |
    \   exe "normal! g`\"" |
    \ endif

autocmd FileType gitcommit startinsert
autocmd FileType svn startinsert

" Remove trailing whitespace on save ignore markdown files
function! s:RemoveTrailingWhitespaces()
  let blacklist = ['md', 'markdown', 'mrd', 'markdown.pandoc']
  if index(blacklist, &ft) < 0
    " Save cursor position
    let l:save = winsaveview()
    " Remove trailing whitespace
    execute('%s/\s\+$//e')
    " Move cursor to original position
    call winrestview(l:save)
  endif
endfunction

au BufWritePre * call <SID>RemoveTrailingWhitespaces()

" This allows you to visually select a section and then hit @ to run a macro on all lines.
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

vnoremap . :norm.<CR>

" Visual search mappings
function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp
endfunction
vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR>

function! RenameFile() abort
  let old_name = expand('%')
  let ext_file = expand('%:e')
  if !empty(ext_file)
    let ext_file = ".".ext_file
  endif
  let x = 0
  let feedkeys = ""
  while x < len(ext_file)
    let x+=1
    let feedkeys .= "\<left>"
  endwhile
  let new_name = input('New file name: ', expand('%').feedkeys, 'file')
  if isdirectory(new_name)
    let new_name = substitute(new_name, "/$", '', 'g')
    let new_name .= '/' . expand('%:t')
    let ext_file = ""
  endif
  if new_name != '' && new_name !=# old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
    redraw!
    echohl ModeMsg | echo "RenameFile: ".old_name. " -> " .new_name | echohl None
  endif
endfunction
nnoremap <Leader>rn :call RenameFile()<cr>

function! s:MkNonExDir(file, buf) abort
    if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
        let dir=fnamemodify(a:file, ':h')
        if !isdirectory(dir)
          call mkdir(dir, 'p')
        endif
    endif
endfunction
augroup BWCCreateDir
    autocmd!
    autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

function! ExpandWidth()
  let b:expandWidth_lastWidth = winwidth(0)
  let maxWidth = max(map(getline(line("w0"),line('w$')), 'len(v:val)')) + 1
  if b:expandWidth_lastWidth > maxWidth
    return
  endif
  let g:expandWidth#defaultMaxWidth = 200
  let widthResult = min([ ( maxWidth + 5 ), g:expandWidth#defaultMaxWidth ])
  execute 'vertical resize ' . widthResult
endfunction
" au BufEnter * :call ExpandWidth()

" stolen from wincent
hi Blank term=bold,reverse ctermfg=248 ctermbg=235
function! Should_colorcolumn() abort
  return index(['diff', 'undotree', 'nerdtree', 'qf'], &filetype) == -1
endfunction
function! Blur_window() abort
  if Should_colorcolumn()
    if !exists('w:wincent_matches')
      " Instead of unconditionally resetting, append to existing array.
      " This allows us to gracefully handle duplicate autocmds.
      let w:wincent_matches=[]
    endif
    let l:height=&lines
    let l:slop=l:height / 2
    let l:start=max([1, line('w0') - l:slop])
    let l:end=min([line('$'), line('w$') + l:slop])
    while l:start <= l:end
      let l:next=l:start + 8
      let l:id=matchaddpos(
            \   'Blank',
            \   range(l:start, min([l:end, l:next])),
            \   1000
            \ )
      call add(w:wincent_matches, l:id)
      let l:start=l:next
    endwhile
  endif
endfunction

function! Focus_window() abort
  if Should_colorcolumn()
    if exists('w:wincent_matches')
      for l:match in w:wincent_matches
        try
          call matchdelete(l:match)
        catch /.*/
          " In testing, not getting any error here, but being ultra-cautious.
        endtry
      endfor
      let w:wincent_matches=[]
    endif
  endif
endfunction
" if exists('*matchaddpos')
  " autocmd BufEnter,FocusGained,VimEnter,WinEnter * call Focus_window()
  " autocmd FocusLost,WinLeave * call Blur_window()
" endif

au BufEnter * call MyLastWindow()
function! MyLastWindow()
  " if the window is quickfix go on
  if &buftype=="quickfix"
    " if this window is last on screen quit without warning
    if winbufnr(2) == -1
      quit!
    endif
  endif
endfunction

au VimEnter * set isk-=.

function! Slow()
  set nocursorcolumn
  set nocursorline
  set norelativenumber
  syntax sync minlines=256
endfunction
command Slow call Slow()

let g:zoomEnter = 0
function! TmuxZoom()
  if g:zoomEnter
    execute("!tmux resize-pane -Z")
  endif
endfunction
function! SetZoomTmux()
  let g:zoomEnter = !g:zoomEnter
endfunction
autocmd FocusGained * call TmuxZoom()
command Zoom call SetZoomTmux()

