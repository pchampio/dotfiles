set nocompatible
runtime! macros/matchit.vim
" Leader Mappings
let mapleader = ","

" Add bundles
call plug#begin('~/.vim/bundle/')

Plug 'KabbAmine/vCoolor.vim'
let g:vcoolor_map = '<c-b>'

" Plug 'gorodinskiy/vim-coloresque'

Plug 'scrooloose/nerdtree'

" NERDTress File highlighting
function! NERDTreeHighlightFile(extension, fg, bg, guifg, guibg)
  exec 'autocmd FileType nerdtree highlight ' . a:extension .' ctermbg='. a:bg .' ctermfg='. a:fg .' guibg='. a:guibg .' guifg='. a:guifg
  exec 'autocmd FileType nerdtree syn match ' . a:extension .' #^\s\+.*'. a:extension .'$#'
  exec 'autocmd FileType nerdtree :vertical resize 31'
endfunction

au VimEnter * call NERDTreeHighlightFile('jade', 'green', 'none', 'green', '#151515')
au VimEnter * call NERDTreeHighlightFile('html', 'green', 'none', 'green', '#151515')
au VimEnter * call NERDTreeHighlightFile('slim', 'green', 'none', 'green', '#151515')
au VimEnter * call NERDTreeHighlightFile('coffee', '5', 'none', '#ff00ff', '#151515')
au VimEnter * call NERDTreeHighlightFile('styl', '5', 'none', '#ff00ff', '#151515')
au VimEnter * call NERDTreeHighlightFile('less', '5', 'none', '#ff00ff', '#151515')
au VimEnter * call NERDTreeHighlightFile('scss', '5', 'none', '#ff00ff', '#151515')
au VimEnter * call NERDTreeHighlightFile('sass', '5', 'none', '#ff00ff', '#151515')
au VimEnter * call NERDTreeHighlightFile('ini', 'yellow', 'none', 'yellow', '#151515')
au VimEnter * call NERDTreeHighlightFile('md', 'blue', 'none', '#3366FF', '#151515')
au VimEnter * call NERDTreeHighlightFile('yml', 'yellow', 'none', 'yellow', '#151515')
au VimEnter * call NERDTreeHighlightFile('config', 'yellow', 'none', 'yellow', '#151515')
au VimEnter * call NERDTreeHighlightFile('rc', 'yellow', 'none', 'yellow', '#151515')
au VimEnter * call NERDTreeHighlightFile('conf', 'yellow', 'none', 'yellow', '#151515')
au VimEnter * call NERDTreeHighlightFile('json', 'yellow', 'none', 'yellow', '#151515')
au VimEnter * call NERDTreeHighlightFile('css', 'cyan', 'none', 'cyan', '#151515')
au VimEnter * call NERDTreeHighlightFile('js', 'cyan', 'none', 'cyan', '#151515')
au VimEnter * call NERDTreeHighlightFile('rb', 'Red', 'none', '#ffa500', '#151515')
au VimEnter * call NERDTreeHighlightFile('php', 'Magenta', 'none', '#ff00ff', '#151515')

let g:NERDTreeRespectWildIgnore = 1

" Like vim-vinegar.
nnoremap <silent> - :silent edit <C-R>=expand('%:p:h')<CR><CR>
nnoremap <Leader>n :NERDTreeToggle<CR>
nnoremap <Leader>k :NERDTreeFind<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let g:NERDTreeWinSize=35
let g:NERDTreeMinimalUI=1

" searching
Plug 'wincent/scalpel'
Plug 'wincent/loupe'
let g:LoupeHighlightGroup='IncSearch'
map <leader><space> <Plug>(LoupeClearHighlight)
let g:LoupeCenterResults=0
let g:LoupeHighlightGroup='IncSearch'
nmap <Nop> <Plug>(LoupeStar)
au VimEnter * unmap <Esc>[200~
au VimEnter * nmap <silent> * *``zz

" enhances Vim's integration with the terminal
Plug 'wincent/terminus'


 " " Ctrl-P FuzzyFinder
" Plug 'ctrlpvim/ctrlp.vim'
" let g:ctrlp_line_prefix = ' '
" let g:ctrlp_map='<c-p>'
" " let g:ctrlp_dotfiles = 1
" let g:ctrlp_prompt_mappings = {
    " \ 'AcceptSelection("v")': ['<c-v>', '<RightMouse>', '<c-s>'],
    " \ 'AcceptSelection("h")': ['<c-x>', '<c-cr>', '<c-i>'],
" \ }
" nnoremap \ :CtrlPLine<cr>
" nnoremap <leader>t :CtrlPTag<cr>

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
fun! s:fzf_root()
  let path = finddir(".git", expand("%:p:h").";")
  return fnamemodify(substitute(path, ".git", "", ""), ":p:h")
endfun
nnoremap <silent> <c-p> :exe 'Files ' . <SID>fzf_root()<CR>
let g:fzf_layout = { 'down': '~40%' }
nnoremap \ :BLines<cr>
nnoremap <leader>b :Buffers
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-s': 'vsplit' }
let g:fzf_buffers_jump = 1
let g:fzf_colors = {
      \ 'fg':      ['fg', 'Normal'],
      \ 'bg':      ['bg', 'Normal'],
      \ 'hl':      ['fg', 'Comment'],
      \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
      \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
      \ 'hl+':     ['fg', 'Statement'],
      \ 'info':    ['fg', 'PreProc'],
      \ 'prompt':  ['fg', 'Conditional'],
      \ 'pointer': ['fg', 'Exception'],
      \ 'marker':  ['fg', 'Keyword'],
      \ 'spinner': ['fg', 'Label'],
      \ 'header':  ['fg', 'Comment'] }

" A collection of +70 language packs for Vim
Plug 'sheerun/vim-polyglot'
let g:polyglot_disabled = ['javascript']
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
let g:markdown_fenced_languages = ["ruby", "C=c", "c", "bash=sh",
      \ "sh", "html", "css", "vim", "python"]
Plug 'othree/yajs.vim'
Plug 'zsiciarz/caddy.vim'

" A Vim plugin which shows a git diff in the numberline
Plug 'airblade/vim-gitgutter'
let g:gitgutter_map_keys = 0

" Insert or delete brackets
Plug 'cohama/lexima.vim'
nnoremap <leader>p :let b:lexima_disabled=1<CR>

" . command after a plugin map
Plug 'tpope/vim-repeat'

" surround
Plug 'tpope/vim-surround'

Plug 'gorkunov/smartpairs.vim'

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

" Aligning text
Plug 'junegunn/vim-easy-align'
nmap ga <Plug>(EasyAlign)
xmap ga <Plug>(EasyAlign)

" Always highlight enclosing tags HTML XML
Plug 'Valloric/MatchTagAlways'

Plug 'ludovicchabant/vim-gutentags'
" Exclude css, html, js files from generating tag files
let g:gutentags_exclude = ['*.css', '*.html', '*.js']
" Where to store tag files
let g:gutentags_cache_dir = '~/.vim/gutentags'
let g:gutentags_project_root = ['Makefile']

" Commanter
Plug 'scrooloose/nerdcommenter'
let NERDUsePlaceHolders=0
let NERDSpaceDelims=1
let g:NERDCustomDelimiters = {
    \ 'c': { 'left' : '//', 'leftAlt' : '/*', 'rightAlt': '*/' },
    \ 'caddy': { 'left' : '#' },
\ }

" syntastic
Plug 'scrooloose/syntastic'

" configure syntastic syntax checking to check on save
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_loc_list_height=5

" THEME-SYNTAX
"Plug 'altercation/vim-colors-solarized'
Plug 'morhetz/gruvbox'
let g:gruvbox_contrast_dark="medium"
let g:gruvbox_contrast_light="medium"

let g:gruvbox_sign_column="dark0"
let g:gruvbox_color_column="dark0"
let g:gruvbox_vert_split="dark0"

" tmux-navigator configuration
Plug 'christoomey/vim-tmux-navigator'

" <leader>u for git like undo
Plug 'simnalamburt/vim-mundo'
nnoremap <leader>u :MundoToggle<CR>
let g:mundo_width=70
let g:mundo_playback_delay=40
let g:mundo_verbose_graph=0

" Plug 'ajh17/VimCompletesMe'
" let g:vcm_direction = 'n'
" let b:vcm_tab_complete = 'tags'

Plug 'Shougo/neocomplete.vim'
" Plug 'wellle/tmux-complete.vim'
let g:neocomplete#enable_at_startup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#auto_completion_start_length = 1
let g:neocomplete#enable_fuzzy_completion = 1
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
inoremap <expr><leader><leader>  pumvisible() ? "\<C-y>" : "\<esc>:w!\<cr>"
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif

Plug 'davidhalter/jedi-vim'
let g:jedi#documentation_command = ""
let g:jedi#usages_command = "<leader>N"
let g:jedi#goto_definitions_command = "<leader>g"
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#smart_auto_mappings = 0

autocmd FileType python setlocal completeopt-=preview
let g:neocomplete#force_omni_input_patterns.python =
      \ '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*'

" Enable omni completion.
augroup COMPLETE
  autocmd!
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
let g:UltiSnipsSnippetDirectories=["UltiSnips", $HOME.'/dotfiles/snippets']

" 'SirVer/ultisnips' options.
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger  = "<leader><leader>"

let g:simpledb_show_timing = 0
Plug 'ivalkeen/vim-simpledb'
Plug 'krisajenkins/vim-postgresql-syntax'

" ----------------------------- END -----------------------------
call plug#end()

" 80 columns
set colorcolumn=80      " highlight the 80 column
set synmaxcol=190

" Theme
colorscheme gruvbox
set background=dark

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

filetype plugin indent on

" Clipboard
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

" Show command
set showcmd

" lightline powerline status
set laststatus=2 " Always display the statusline in all windows

" highlight vertical column of cursor
au WinLeave * set nocursorline nocursorcolumn
au WinEnter * set cursorline
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

" Softtabs, 2 spaces
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
set list listchars=tab:▸\ ,trail:·,extends:›,precedes:‹
highlight SpecialKey ctermbg=none cterm=none

set spellfile=~/dotfiles/spell/ownSpellFile.utf-8.add

set ttyfast    " u got a fast terminal
" set lazyredraw
set fillchars=vert:\|

nnoremap <Leader>zz :let &scrolloff=999-&scrolloff<CR>
set so=4

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

" ALT keys Mappings
function! Altmap(char)
  if has('gui_running') | return ' <A-'.a:char.'> ' | else | return ' <Esc>'.a:char.' '|endif
endfunction

" spell
execute 'nnoremap'.Altmap('s')."ei<c-x>s"
execute 'nnoremap'.Altmap('l')."[s1z=``"

"Moving lines
execute 'nnoremap'.Altmap('k').":m .-2<CR>=="
execute 'nnoremap'.Altmap('j').":m .+1<CR>=="
execute "vnoremap <up> :m '<-2<CR>gv=gv"
execute "vnoremap <Down> :m '>+1<CR>gv=gv"

" Quicker navigation
noremap H 0^
noremap L g_

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

vnoremap J }
vnoremap K {
noremap j gj
noremap k gk

inoremap ;; <esc>A;<esc>

" Switch CMD to the dir of the open buffer
noremap <leader>cd :lcd <c-r>=expand("%:p:h")<cr>

" Sudo save
cnoreabbrev w!! w !sudo tee > /dev/null %

" Insert New line
noremap U o<ESC>

" Perfect tag closer (xml)
inoremap </ </<C-x><C-o>

" Spell-Checking
" zg add word to the spelling dictionary
" zw remove it
nnoremap <silent> <leader>en <Esc>:silent setlocal spell! spelllang=en<CR>
nnoremap <silent> <leader>fr <Esc>:silent setlocal spell! spelllang=fr<CR>
nnoremap <silent> <leader>all <Esc>:silent setlocal spell! spelllang=fr,en<CR>
nnoremap <silent> <leader>a <Esc>zg
nnoremap <silent> <leader>d <Esc>zw
hi clear SpellBad
hi clear SpellRare
hi clear SpellLocal
hi SpellBad   cterm=underline ctermfg=9  ctermbg=0 gui=undercurl
hi SpellCap   cterm=underline ctermfg=14 ctermbg=0 gui=undercurl
hi SpellRare  cterm=underline ctermfg=13 ctermbg=0 gui=undercurl
hi SpellLocal cterm=underline ctermfg=11 ctermbg=0 gui=undercurl

autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en
autocmd FileType gitcommit setlocal spell spelllang=fr,en

" no more ex Mode
nnoremap Q <nop>

" use space for moving to the newt word
noremap <space> 2w

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

cnoreabbrev push !cat\|push <c-r>=expand('%:t')<cr> > /tmp/up.tmp<cr>u:vs /tmp/up.tmp<cr> :set ft=help <cr>

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
    \   line("'\"") > 1 && line("'\"") < line("$") |
    \   exe "normal! g`\"" |
    \ endif

autocmd FileType gitcommit startinsert

" Remove trailing whitespace on save ignore markdown files
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
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction

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
  let new_name = input('New file name: ', substitute(expand('%'), expand('%:t'), '', 'g'), 'file')
  if isdirectory(new_name)
    let new_name = substitute(new_name, "/$", '', 'g')
    let new_name .= '/' . expand('%:t')
  endif
  if new_name != '' && new_name != old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
  endif
  redraw!
endfunction
nnoremap <Leader>rn :call RenameFile()<cr>

function s:MkNonExDir(file, buf) abort
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
  if b:expandWidth_lastWidth > maxWidth || &filetype == "nerdtree"
    return
  endif
  let g:expandWidth#defaultMaxWidth = 200
  let widthResult = min([ ( maxWidth + 5 ), g:expandWidth#defaultMaxWidth ])
  execute 'vertical resize ' . widthResult
endfunction
au BufEnter * :call ExpandWidth()

hi! link Search SpellBad
au VimEnter * set isk-=.
