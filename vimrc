" Leader Mappings
let mapleader = ","

" Add bundles
call plug#begin('~/.vim/bundle/')

" Breakdown Vim's --startuptime output
" Plug 'tweekmonster/startuptime.vim'

if exists('veonim')
  set guifont=Hack
  set guicursor=n:block-CursorNormal,i:hor10-CursorInsert,v:block-CursorVisual
  set linespace=15
endif

if !exists('$TMUX')

  " use neovim-remote (pip3 install neovim-remote) allows
  " opening a new split inside neovim instead of nesting
  " neovim processes for git commit
  let $GIT_EDITOR  = 'nvr -cc split --remote-wait +"setlocal bufhidden=delete"'
  let $EDITOR      = 'nvr'

  " abstraction on top of neovim terminal
  Plug 'kassio/neoterm'

  " send stuff to REPL using NeoTerm
  nnoremap <silent> <c-s>l :TREPLSendLine<CR>
  vnoremap <silent> <c-s>l :TREPLSendSelection<CR>

  " simulate tmux shortcuts in neovim
  Plug 'Vigemus/nvimux', {'do': 'cp -r ./lua $HOME/.config/nvim/'}

lua << EOF
local nvimux = require('nvimux')
-- Nvimux configuration
nvimux.config.set_all{
  prefix = '<C-Space>',
  new_window = 'enew | Tnew',
  open_term_by_default = true,
  new_window_buffer = 'single',
}
-- Nvimux custom bindings
nvimux.bindings.bind_all{
  {'i', ':NvimuxHorizontalSplit', {'n', 'v', 'i', 't'}},
  {'s', ':NvimuxVerticalSplit', {'n', 'v', 'i', 't'}},
}
-- Required so nvimux sets the mappings correctly
nvimux.bootstrap()
EOF

  nnoremap <silent> <A-n> :NvimuxNewTab<cr>

  " easily escape terminal
  tnoremap <leader><esc> <C-\><C-n>
  " start insert mode terminal
  autocmd BufWinEnter,WinEnter term://* startinsert
  autocmd BufWinEnter,WinEnter term://* redraw!

  " Move around
  tnoremap <c-h> <C-\><C-N><C-w>h
  tnoremap <c-j> <C-\><C-N><C-w>j
  tnoremap <c-k> <C-\><C-N><C-w>k
  tnoremap <c-l> <C-\><C-N><C-w>l

  " Tab movement
  nnoremap <silent> <M-l> :tabnext<cr>
  nnoremap <silent> <M-h> :tabprevious<cr>
  tnoremap <silent> <M-l> <C-\><C-n>:tabnext<cr>
  tnoremap <silent> <M-h> <C-\><C-n>:tabprevious<cr>

  " resizing a window split
  tnoremap <C-Right> <C-\><C-n><C-w>10<I
  tnoremap <C-Down> <C-\><C-n><C-W>5-I
  tnoremap <C-Up> <C-\><C-n><C-W>5+I
  tnoremap <C-Left> <C-\><C-n><C-w>10>I


  let g:neoterm_autoinsert=1

  Plug 'szw/vim-maximizer'
  nnoremap <C-Space><Space> :MaximizerToggle!<CR>
  tnoremap <C-Space><Space> <C-\><C-N>:MaximizerToggle!<CR>

  Plug 'kh3phr3n/tabline'

endif

" Git
Plug 'tpope/vim-fugitive' " Git wrapper
nnoremap <silent> - :Gstatus<cr>:10wincmd_<cr>
au FileType gitrebase nnoremap <buffer> <silent> <c-s><c-s> :s/^#\?\w\+/squash/<cr>:noh<cr>
set diffopt+=vertical

Plug 'sodapopcan/vim-twiggy' " Git branch management
let g:twiggy_close_on_fugitive_command = 1
nnoremap _ :Twiggy<cr>

" tmux-navigator configuration
Plug 'christoomey/vim-tmux-navigator'

" searching
Plug 'wincent/loupe'
map <leader><space> <Plug>(LoupeClearHighlight)

" searching multiple files
Plug 'wincent/ferret'
" prevent any default mapping from being configured
let g:FerretMap=0
nmap <leader>* <Plug>(FerretAckWord)
" nnoremap <c-n> :cnf<cr>
" nnoremap <c-p> :cpf<cr>
nmap <leader>E <Plug>(FerretAcks)
nnoremap g/ :Ack<space>

" enhances Vim's integration with the terminal
Plug 'wincent/terminus'

" Fuzzy finder
Plug 'ctrlpvim/ctrlp.vim'
" Checkout yoink mapping
let g:ctrlp_map=''
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
autocmd StdinReadPre * let g:isReadingFromStdin = 1
autocmd VimEnter * if (argc() && isdirectory(argv()[0]) || !argc()) && !exists('g:isReadingFromStdin') | execute' CtrlP' | endif

" Syntax highlight
" A collection of +70 language packs for Vim
Plug 'sheerun/vim-polyglot'
Plug 'adimit/prolog.vim'

" Text outlining and task management
Plug 'jceb/vim-orgmode'

" Theme
Plug 'chriskempson/base16-vim'

" syntastic
Plug 'w0rp/ale'
let g:ale_lint_on_text_changed = 'never'
let g:ale_list_window_size = 5
let g:ale_lint_on_enter = 0
let g:ale_open_list = 1
hi! link ALEErrorSign SpellBad
hi! link ALEWarningSign SpellRare
" navigate between errors
nmap <silent> [e <Plug>(ale_next_wrap)
nmap <silent> ]e <Plug>(ale_previous_wrap)

let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'markdown': ['remove_trailing_lines'],
\   'liquid': ['remove_trailing_lines'],
\   'python': ['autopep8'],
\   'go': ['gofmt'],
\}
let g:ale_fix_on_save = 1
let g:ale_python_autopep8_options = '--max-line-length 115'

" A Vim plugin which shows a git diff in the numberline
Plug 'mhinz/vim-signify'
let g:signify_sign_change = '~'
nmap ]g <plug>(signify-next-hunk)
nmap [g <plug>(signify-prev-hunk)

" surround
Plug 'machakann/vim-sandwich'
" More conf in vim/plugin/surround.vim

" highlight yank
Plug 'machakann/vim-highlightedyank'
autocmd ColorScheme * hi HighlightedyankRegion guifg=#d33682 gui=underline,bold

let g:highlightedyank_highlight_duration = 500

" Aligning text
Plug 'junegunn/vim-easy-align'
nmap <leader>ga <Plug>(EasyAlign)
xmap <leader>ga <Plug>(EasyAlign)

" simplifies the transition between multiline and single-line code
Plug 'AndrewRadev/splitjoin.vim'
let g:splitjoin_trailing_comma = 1

" move function arguments
Plug 'AndrewRadev/sideways.vim'
nnoremap <silent> <A-.> :SidewaysRight<cr>
nnoremap <silent> <A-,> :SidewaysLeft<cr>
"argument text object.
omap aa <Plug>SidewaysArgumentTextobjA
xmap aa <Plug>SidewaysArgumentTextobjA
omap ia <Plug>SidewaysArgumentTextobjI
xmap ia <Plug>SidewaysArgumentTextobjI

Plug 'haya14busa/vim-edgemotion'
map J <Plug>(edgemotion-j)
map K <Plug>(edgemotion-k)


" The missing motion for Vim
Plug 'justinmk/vim-sneak'
let g:sneak#prompt = 'Sneak >>> '
let g:sneak#label = 1 " EasyMotion like
let g:sneak#use_ic_scs = 1 " Case sensitivity
" S is for sandwich
nmap t <Plug>Sneak_s
nmap T <Plug>Sneak_S
" Clever-f mappings
let g:sneak#s_next = 1
map f <Plug>Sneak_f
map F <Plug>Sneak_F
map : <Plug>Sneak_;
" map t <Plug>Sneak_t
" Clever-f highlight <3
autocmd ColorScheme * hi Sneak guifg=red guibg=NONE gui=bold,underline
autocmd ColorScheme * hi SneakLabel guifg=red guibg=#eee8d5 gui=bold,underline

Plug 'svermeulen/vim-yoink'
nmap <c-n> <plug>(YoinkPostPasteSwapBack)
nmap p <plug>(YoinkPaste_p)
nmap P <plug>(YoinkPaste_P)
let g:yoinkSyncSystemClipboardOnFocus = 0
let g:yoinkMaxItems = 8
let g:yoinkMoveCursorToEndOfPaste = 1
let g:yoinkSwapClampAtEnds = 0
" Ctrlp fuzzy finder w/ yoink
nmap <expr> <c-p> yoink#isSwapping() ? '<plug>(YoinkPostPasteSwapForward)' : '<Plug>(ctrlp)'
" nmap <c-p> <Plug>(ctrlp)
nmap [y <plug>(YoinkRotateBack)
nmap ]y <plug>(YoinkRotateForward)
nmap y <plug>(YoinkYankPreserveCursorPosition)
xmap y <plug>(YoinkYankPreserveCursorPosition)

Plug 'svermeulen/vim-subversive'
nmap r <plug>(SubversiveSubstitute)
nmap rr <plug>(SubversiveSubstituteLine)
xmap r <plug>(SubversiveSubstitute)
xmap p <plug>(SubversiveSubstitute)
xmap P <plug>(SubversiveSubstitute)
" cursor will not move when substitutions are applied
let g:subversivePreserveCursorPosition = 1
noremap R r

" ie = inner entire buffer
onoremap ie :exec "normal! ggVG"<cr>

nmap <silent> <leader>e <plug>(SubversiveSubstituteWordRange)ie
nmap <silent> <leader>ee ;call sneak#cancel()<cr><plug>(SubversiveSubstituteRange)
xmap <silent> <leader>e <plug>(SubversiveSubstituteRange)ie

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

" insert or delete brackets
Plug 'cohama/lexima.vim'

" text objects and motions for Python
Plug 'jeetsukumaran/vim-pythonsense'

" user Text objects
Plug 'kana/vim-textobj-user'

" funcions Text-object
Plug 'kana/vim-textobj-function'
" heuristic function Text-object
Plug 'haya14busa/vim-textobj-function-syntax'

" comment Text-object.
Plug 'glts/vim-textobj-comment'
let g:textobj_comment_no_default_key_mappings = 1
omap agc <Plug>(textobj-comment-a)
omap igc <Plug>(textobj-comment-i)
omap agC <Plug>(textobj-comment-big-a)
xmap agc <Plug>(textobj-comment-a)
xmap igc <Plug>(textobj-comment-i)
xmap agC <Plug>(textobj-comment-big-a)

" word-based columns Text-object
Plug 'idbrii/textobj-word-column.vim'

" stop repeating the basic movement keys
Plug 'takac/vim-hardtime'
let g:hardtime_default_on = 1
let g:hardtime_showmsg = 1
let g:hardtime_ignore_quickfix = 1
let g:hardtime_maxcount = 3
let g:list_of_normal_keys = ["h", "j", "k", "l"]
let g:hardtime_ignore_buffer_patterns = [ "fugitive.*", "\.git.*"]

"  Snippets
Plug 'SirVer/ultisnips'
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger  = "<leader><leader>"
" Snippets are separated from the engine.
Plug 'honza/vim-snippets'
let g:UltiSnipsSnippetDirectories=[$HOME.'/dotfiles/snippets', 'snips', 'UltiSnips']

" Dark powered asynchronous
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" let g:deoplete#enable_at_startup = 1 " Use Idleboot (faster boot-time)
" pip3 install --user --upgrade pynvim

" Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}}

inoremap <expr> <Tab> pumvisible() ? "\<c-y>" : "\<Tab>"

set completeopt=noinsert,menuone,noselect

" LSP
Plug 'autozimu/LanguageClient-neovim', {
      \ 'branch': 'next',
      \ 'do': 'bash install.sh',
      \ 'for': ['go', 'java', 'python', 'javascript', 'typescript', 'cpp']}

let g:LanguageClient_loggingFile = '/tmp/lc.log'
let g:LanguageClient_loggingLevel = 'WARN'
let g:LanguageClient_settingsPath = '/home/drakirus/dotfiles/LSP_settings.json'
" let g:LanguageClient_diagnosticsEnable = 0

let g:LanguageClient_serverCommands = {
    \ 'go': ['/bin/go-langserver'],
    \ 'java': ['/bin/jdtls'],
    \ 'python': ['/home/drakirus/.local/bin/pyls'],
    \ 'javascript': ['/usr/bin/javascript-typescript-stdio'],
    \ 'typescript': ['/usr/bin/javascript-typescript-stdio'],
    \ 'cpp': ['cquery', '--init={"cacheDirectory": "/tmp/.cache/cquery/"}'],
    \ }

function! LC_maps()
  if has_key(g:LanguageClient_serverCommands, &filetype)
    nnoremap <buffer> <silent> <leader>== :call LanguageClient_textDocument_formatting()<CR>
    nnoremap <buffer> <silent> <leader>K :call LanguageClient#textDocument_hover()<CR>
    nnoremap <buffer> <leader>ll :call LanguageClient_contextMenu()<CR>
    nnoremap <silent> <leader>g :call LanguageClient_textDocument_definition()<CR>
    let b:ale_enabled = 0
  else
    noremap <leader>g <c-]>
  endif
endfunction

autocmd FileType * call LC_maps()


" LANGUAGE SPECIFIC
" Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
" use goimports for formatting
" let g:go_fmt_command = "goimports"


Plug 'christoomey/vim-tmux-runner'

autocmd FileType prolog :nnoremap <buffer> <silent> <cr> :execute "normal vip\<Plug>NERDCommenterToggle"<cr>
      \ :VtrOpenRunner {'orientation': 'h', 'percentage': 30, 'cmd': 'swipl'}<cr>
      \ :VtrSendCommand! abort. %; swipl<cr>
      \ :VtrSendCommand! [<c-r>=expand('%:r')<cr>].<cr> vip:VtrSendLinesToRunner<cr>
\ :undo<cr>

" autocmd FileType sh,bash,zsh :nnoremap <cr> mavip:VtrSendLinesToRunner<cr>`a

call plug#end()

" Wait until idle to run additional "boot" commands.
augroup Idleboot
  autocmd!
  if has('vim_starting')
    set updatetime=2000
    autocmd CursorHold,CursorHoldI * call s:idleboot()
  endif
augroup END

function! s:idleboot() abort
  " Make sure we automatically call s:idleboot() only once.
  augroup Idleboot
    autocmd!
  augroup END

  " message info
  echohl ModeMsg | echon '-- Deoplete enabled --' | echohl None
  call timer_start(2000, function('execute', ['echo ""'])) " cleanup

  call deoplete#enable()
endfunction


" Theme
set termguicolors
colorscheme base16-solarized-light
set background=light

" Make comments italic
highlight Comment gui=italic

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

" above and below the cursor when scrolling
set scrolloff=3
set sidescrolloff=7

nnoremap <c-e> 5<c-e>
nnoremap <c-y> 5<c-y>

" Clipboard
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

" highlight vertical column of cursor
set cursorline

" relativ number
set relativenumber
set number

" tell it to use an undo file
set undofile
" set a directory to store the undo history
set undodir=~/.vimundo/
set noswapfile   " No *.swp

" store commands
set shada=!,'100,<50,s10,

" Softtabs, 2 spaces tabs
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

set inccommand=split
" set wildoptions=pum


" 80 columns
set colorcolumn=80      " highlight the 80 column

set nowrap

" Display extra whitespace
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
" To make vsplit put the new buffer on the right/below of the current buffer
set splitbelow
set splitright

" resizing a window split
nnoremap <Left> <C-w>10<
nnoremap <Down> <C-W>5-
nnoremap <Up> <C-W>5+
nnoremap <Right> <C-w>10>

"Moving lines
nnoremap <A-k> :m .-2<CR>==
nnoremap <A-j> :m .+1<CR>==
vnoremap <up>  :m '<-2<CR>gv=gv
vnoremap <Down> :m '>+1<CR>gv=gv

" Quicker navigation start - end of line
noremap H 0^
xmap H ^
omap H ^
noremap L g_

" overrides the change operations don't affect the current yank
nnoremap c "_c
nnoremap C "_C

nnoremap <leader><leader> :w!<cr>

vnoremap <silent><expr> ++ VMATH_YankAndAnalyse()

noremap <Leader>G :vsp <cr> <c-]>

inoremap <c-l> <esc>A

noremap j gj
noremap k gk

noremap <leader>cd :lcd <c-r>=expand("%:p:h")<cr>

" no more ex Mode
nnoremap Q <nop>

" Insert New line
noremap <silent> U :call append(line('.'), '')<CR>j

" Spell-Checking
" zg add word to the spelling dictionary
" zw remove it
nnoremap <silent> <leader>sen <Esc>:silent setlocal spell! spelllang=en<CR>
nnoremap <silent> <leader>sfr <Esc>:silent setlocal spell! spelllang=fr<CR>
nnoremap <silent> <leader>sall <Esc>:silent setlocal spell! spelllang=fr,en<CR>
nnoremap <silent> <leader>sa <Esc>zg
nnoremap <silent> <leader>sd <Esc>zug
inoremap <leader>a à
inoremap <leader>u ù
inoremap <c-u> ȗ
inoremap <leader>e é
inoremap <c-e> è
autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en tw=80

" nnoremap <A-s> w[sei<C-x>s
inoremap <expr> <A-s>  pumvisible() ?  "\<C-n>" : "\<C-x>s"
nnoremap <expr> <A-s> pumvisible() ?  "i\<C-n>" : "w[sei\<C-x>s"

hi SpellBad  gui=underline guifg=#dc322f
hi SpellCap  gui=undercurl guifg=#6c71c4
hi SpellRare gui=undercurl guifg=#6c71c4
hi SpellLocal gui=undercurl guifg=#eee8d5

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
vnoremap ; :
cnoreabbrev ; :

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

" Visual search mappings
function! s:VSetSearch()
  let temp = @@
  norm! gvy
  let @/ = '\V' . substitute(escape(@@, '\'), '\n', '\\n', 'g')
  let @@ = temp
endfunction
vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR>

" Close vim if the quickfix window or other listed window
" is the only window visible
autocmd WinEnter * call s:CloseOnlyWindow()

function! s:CloseOnlyWindow() abort
  if winnr('$') == 1
    let s:buftype =  getbufvar(winbufnr(winnr()), "&buftype")
    if s:buftype == "quickfix" || &filetype == 'twiggy'
      q
    endif
  endif
endfunction

function! RenameFile() abort
  let old_name = expand('%')
  let ext_file = expand('%:e')
  if !empty(ext_file) | let ext_file = ".".ext_file | endif
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
    if !isdirectory(dir) | call mkdir(dir, 'p') | endif
  endif
endfunction
augroup BWCCreateDir
  autocmd!
  autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END
