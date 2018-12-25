" Leader Mappings
let mapleader = ","

" Add bundles
call plug#begin('~/.vim/bundle/')

" highlight yank
Plug 'machakann/vim-highlightedyank'
hi! link HighlightedyankRegion GitGutterChange
let g:highlightedyank_highlight_duration = 500

" tmux-navigator configuration
Plug 'christoomey/vim-tmux-navigator'

" key bindings for quickly moving between windows
" h left, l right, k up, j down
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
nnoremap <c-k> <c-w>k
nnoremap <c-j> <c-w>j

" searching
Plug 'wincent/scalpel'
Plug 'wincent/loupe'
let g:LoupeHighlightGroup='IncSearch'
map <leader><space> <Plug>(LoupeClearHighlight)
let g:LoupeCenterResults=0
let g:LoupeHighlightGroup='IncSearch'
nmap <Nop> <Plug>(LoupeStar)

" searching multiple files
Plug 'wincent/ferret'
let g:FerretMap=0
nmap <leader>* <Plug>(FerretAckWord)
nnoremap <c-n> :cnf<cr>
nnoremap <c-b> :cpf<cr>
nmap <leader>E <Plug>(FerretAcks)
nnoremap g/ :Ack<space>


" enhances Vim's integration with the terminal
Plug 'wincent/terminus'

" Fuzzy finder
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
if executable('rg')
  set grepprg=rg\ --color=never
  let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
  let g:ctrlp_use_caching = 0
endif
" Ctrlp Style defined in autoload
let g:ctrlp_status_func = {
  \ 'main': 'CtrlP_main_status',
  \ 'prog': 'CtrlP_progress_status'
  \}
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
let g:ctrlp_default_input = 1
autocmd VimEnter * if (argc() && isdirectory(argv()[0]) || !argc()) | execute' CtrlP' | endif

" Another Fuzzy finder
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" A collection of +70 language packs for Vim
Plug 'sheerun/vim-polyglot'

" Theme
Plug 'chriskempson/base16-vim'

" syntastic
Plug 'w0rp/ale'
let g:ale_lint_on_text_changed = 'never'
let g:ale_list_window_size = 5
let g:ale_lint_on_enter = 0
let g:ale_open_list = 1
nnoremap <leader>dd :ALEDisable<CR>
hi! link ALEErrorSign SpellBad
hi! link ALEWarningSign SpellRare


" A Vim plugin which shows a git diff in the numberline
Plug 'mhinz/vim-signify'
let g:signify_sign_change = '~'
nmap [g <plug>(signify-next-hunk)
nmap ]g <plug>(signify-prev-hunk)

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

" Replace + motion
Plug 'vim-scripts/ReplaceWithRegister'
nmap r  <Plug>ReplaceWithRegisterOperator
nmap rr <Plug>ReplaceWithRegisterLine
xmap r  <Plug>ReplaceWithRegisterVisual
noremap R r

" Aligning text
Plug 'junegunn/vim-easy-align'
nmap <leader>ga <Plug>(EasyAlign)
xmap <leader>ga <Plug>(EasyAlign)

" move function arguments
Plug 'AndrewRadev/sideways.vim'
nnoremap <A-.> :SidewaysRight<cr>
nnoremap <A-,> :SidewaysLeft<cr>
"argument text object.
omap aa <Plug>SidewaysArgumentTextobjA
xmap aa <Plug>SidewaysArgumentTextobjA
omap ia <Plug>SidewaysArgumentTextobjI
xmap ia <Plug>SidewaysArgumentTextobjI

Plug 'rhysd/clever-f.vim'
let g:clever_f_chars_match_any_signs = ';'

" Commanter
Plug 'scrooloose/nerdcommenter'
let NERDUsePlaceHolders=0
let NERDSpaceDelims=1 " add space after the comment symbol
let g:NERDCustomDelimiters = {
    \ 'c': { 'left' : '//', 'leftAlt' : '/*', 'rightAlt': '*/' },
    \ 'javascript.jsx': { 'left' : '//', 'leftAlt' : '/*', 'rightAlt': '*/' },
    \ 'caddy': { 'left' : '#' },
\ }

" <leader>u for git like undo
Plug 'simnalamburt/vim-mundo'
nnoremap <leader>u :MundoToggle<CR>
let g:mundo_width=70
let g:mundo_playback_delay=40
let g:mundo_verbose_graph=0

" Insert or delete brackets
Plug 'cohama/lexima.vim'

"  Snippets
Plug 'SirVer/ultisnips'
" Snippets are separated from the engine.
Plug 'honza/vim-snippets'
" let g:UltiSnipsSnippetsDir="~/.vim/bundle/vim-snippets/"
let g:UltiSnipsSnippetDirectories=[$HOME.'/dotfiles/snippets', 'snips', 'UltiSnips']
" 'SirVer/ultisnips' options.
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger  = "<leader><leader>"

" COMPLETION
Plug 'ncm2/ncm2'
Plug 'roxma/nvim-yarp'

" NOTE: you need to install completion sources to get completions.
Plug 'ncm2/ncm2-path'
Plug 'ncm2/ncm2-bufword'
Plug 'wellle/tmux-complete.vim'
Plug 'ncm2/ncm2-ultisnips'

inoremap <expr> <Tab> pumvisible() ? "\<c-y>" : "\<Tab>"

" enable ncm2 for all buffers
autocmd BufEnter * call ncm2#enable_for_buffer()

" IMPORTANTE: :help Ncm2PopupOpen for more information
set completeopt=noinsert,menuone,noselect


" LSP
Plug 'autozimu/LanguageClient-neovim', {
      \ 'branch': 'next',
      \ 'do': 'bash install.sh',
      \ }


nnoremap <leader>ll :call LanguageClient_contextMenu()<CR>
nnoremap <silent> <leader>g :call LanguageClient#textDocument_definition()<CR>

let g:LanguageClient_serverCommands = {
    \ 'go': ['go-langserver'],
    \ }
let g:LanguageClient_loggingFile = '/tmp/lc.log'
let g:LanguageClient_loggingLevel = 'DEBUG'
let g:LanguageClient_settingsPath = '/home/drakirus/dotfiles/LSP_settings.json'


Plug 'christoomey/vim-tmux-runner'

" LANGUAGE SPECIFIC
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
" use goimports for formatting
let g:go_fmt_command = "goimports"

Plug 'adimit/prolog.vim'
autocmd FileType prolog :nnoremap <buffer> <silent> <cr> :execute "normal vip\<Plug>NERDCommenterToggle"<cr>
      \ :VtrOpenRunner {'orientation': 'h', 'percentage': 30, 'cmd': 'swipl'}<cr>
      \ :VtrSendCommand! abort. %; swipl<cr>
      \ :VtrSendCommand! [<c-r>=expand('%:r')<cr>].<cr> vip:VtrSendLinesToRunner<cr>
\ :undo<cr>

autocmd FileType sh,bash,zsh :nnoremap <cr> mavip:VtrSendLinesToRunner<cr>`a


call plug#end()

" Theme
set termguicolors
colorscheme base16-solarized-light
set background=light

" Ignore
set wildignore+=.hg,.git,.svn                           " Version control
set wildignore+=*.aux,*.out,*.toc                       " LaTeX intermediate files
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg          " binary images
set wildignore+=*.luac                                  " Lua byte code
set wildignore+=*.o,*.lo,*.obj,*.exe,*.dll,*.manifest   " compiled object files
set wildignore+=*.pyc                                   " Python byte code
set wildignore+=*.spl                                   " compiled spelling word lists
set wildignore+=*.sw?                                   " Vim swap files set wildignore+=*~,*.swp,*.tmp
set wildignore+=*.DS_Store?                             " OSX bullshit
set wildignore+=*.sqlite3

" Required for operations modifying multiple buffers like rename.
set hidden

" Clipboard
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

" highlight vertical column of cursor
set cursorline

" relativ number
set numberwidth=4
set relativenumber
set number

" tell it to use an undo file
set undofile
" set a directory to store the undo history
set undodir=~/.vimundo/

" Softtabs, 2 spaces tabs
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

set noswapfile   " No *.swp

" Case
set smartcase
set ignorecase

" 80 columns
set colorcolumn=80      " highlight the 80 column
set fillchars=vert:\|


" Display extra whitespace
set sidescroll=1
set nowrap
set list listchars=tab:▸\ ,trail:·,extends:›,precedes:‹
" set list listchars=tab:\ \ ,trail:·,extends:›,precedes:‹
highlight SpecialKey ctermbg=none cterm=none

set spellfile=~/dotfiles/spell/ownSpellFile.utf-8.add

" UTF-8
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set fileformat=unix

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

"Moving lines
nnoremap <A-k> :m .-2<CR>=="
nnoremap <A-j> :m .+1<CR>=="
vnoremap <up>  :m '<-2<CR>gv=gv"
vnoremap <Down> :m '>+1<CR>gv=gv"

" Quicker navigation
noremap H 0^
xmap H ^
omap H ^
noremap L g_

nnoremap c "_c
nnoremap C "_C

" Mapping
nnoremap <leader><leader> :w!<cr>

vnoremap <silent><expr>  ++  VMATH_YankAndAnalyse()
nnoremap <silent> ++ vip++

noremap <leader>g <c-]>
noremap <Leader>G :vsp <cr> <c-]>

inoremap <c-l> <esc>A

vnoremap J }
vnoremap K {
noremap j gj
noremap k gk

nnoremap <Leader>D yyp

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

vnoremap . :norm.<CR>

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
