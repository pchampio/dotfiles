scriptencoding utf-8

" cf the default statusline: %<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P


  hi statusLine ctermfg=237 ctermbg=248 cterm=bold gui=bold guifg=#658b63 guibg=#EEE8D5
  hi statusLineNC ctermfg=237 ctermbg=248 cterm=italic guibg=#eee8d5 gui=italic guifg=#658b63

  hi User1 ctermfg=237 ctermbg=248 cterm=italic guibg=#eee8d5
  hi User3 ctermfg=237 ctermbg=248 cterm=bold gui=bold guifg=#658b63 guibg=#EEE8D5
  hi User4 ctermfg=124 ctermbg=248 guibg=#eee8d5 guifg=#AF0000
  hi User5 ctermfg=246 ctermbg=236 guibg=#586E75 guifg=#F9E4CC
  hi User2 ctermfg=246 ctermbg=236 cterm=bold ctermbg=236 guibg=#586E75 guifg=#F9E4CC
  hi User6 ctermfg=237 ctermbg=248 guibg=#eee8d5 guifg=#586E75
  hi User7 ctermfg=229 ctermbg=124 cterm=bold guifg=#F2F0EB guibg=#AF0000
  hi User8 ctermfg=166 ctermbg=248 cterm=bold gui=bold guifg=#fabd2f guibg=#eee8d5

" ssh
let g:remoteSession = ($SSH_CONNECTION != "")

let &t_ZH="\e[3m"
let &t_ZR="\e[23m"

if has('statusline')

  set statusline=%7*                         " Switch to User7 highlight group
  if !g:remoteSession
    " set statusline+=%{statusline#gutterpadding(1)}
    set statusline+=\                          " Space.
  else
    set statusline+=\                          " Space.
  endif
  set statusline+=%n                         " Buffer number.
  set statusline+=\                          " Space.
  set statusline+=%*                         " Reset highlight group.
  set statusline+=%4*                        " Switch to User4 highlight group (Powerline arrow).
  set statusline+=                          " Powerline arrow.

  set statusline+=%*                         " Reset highlight group.
  set statusline+=\                          " Space.
  set statusline+=%<                         " Truncation point, if not enough width available.
  set statusline+=%{statusline#fileprefix()} " Relative path to file's directory.
  set statusline+=%3*                        " Switch to User3 highlight group (bold).
  set statusline+=%t                         " Filename.
  set statusline+=%*                         " Reset highlight group.
  set statusline+=\                          " Space.
  set statusline+=%1*                        " Switch to User1 highlight group (italics).

  " Needs to be all on one line:
  "   %(                   Start item group.
  "   [                    Left bracket (literal).
  "   %M                   Modified flag: ,+/,- (modified/unmodifiable) or nothing.
  "   %R                   Read-only flag: ,RO or nothing.
  "   %{statusline#ft()}   Filetype (not using %Y because I don't want caps).
  "   %{statusline#fenc()} File-encoding if not UTF-8.
  "   ]                    Right bracket (literal).
  "   %)                   End item group.
  set statusline+=%([%M%R%{statusline#ft()}%{statusline#fenc()}]%)
  set statusline+=%*   " Reset highlight group.
  set statusline+=%=   " Split point for left and right groups.

  set statusline+=%{WordCount()}
  if !g:remoteSession
    set statusline+=%([%{gutentags#statusline('Tags..')}%{&spell?&spelllang:''}%{statusline#jobs()}]%)
  endif
  set statusline+=%6*  " Switch to User6 highlight group (Powerline arrow).
  set statusline+=\    " Space.
  set statusline+=    " Powerline arrow.
  set statusline+=%5*  " Switch to User5 highlight group.
  set statusline+=\    " Space.
  set statusline+=ℓ    " (Literal, \u2113 "SCRIPT SMALL L").
  set statusline+=\    " Space.
  set statusline+=%l   " Current line number.
  set statusline+=/    " Separator.
  set statusline+=%L   " Number of lines in buffer.
  set statusline+=\    " Space.
  set statusline+=𝚌    " (Literal, \u1d68c "MATHEMATICAL MONOSPACE SMALL C").
  set statusline+=\    " Space.
  set statusline+=%v   " Current virtual column number.
  set statusline+=\    " Space.
  set statusline+=%2*  " Switch to User2 highlight group.
  set statusline+=%P   " Percentage through buffer.
  set statusline+=\    " Space.
  set statusline+=%*   " Reset highlight group.
endif
