scriptencoding utf-8

" Highlight

hi statusLine guibg=#EEE8D5 gui=italic
hi statusLineNC guibg=#eee8d5 gui=italic

hi User1 guibg=#eee8d5 guifg=#586E75 gui=italic

" hi! link User3 User1 " with bold
exec 'hi User3 gui=bold' .
      \' guibg=' . synIDattr(synIDtrans(hlID('User1')), 'bg', 'gui')
      \' guifg=' . synIDattr(synIDtrans(hlID('User1')), 'fg', 'gui')


hi User4 guibg=#eee8d5 guifg=#AF0000
hi User5 guibg=#586E75 guifg=#F9E4CC
hi User2 guibg=#586E75 guifg=#F9E4CC
hi User6 guibg=#eee8d5 guifg=#586E75
hi User7 guibg=#AF0000 guifg=#F2F0EB
hi User8 guibg=#eee8d5 guifg=#d33682 gui=italic

" END

let &t_ZH="\e[3m"
let &t_ZR="\e[23m"

if has('statusline')

  set statusline=%7*                         " Switch to User7 highlight group
  set statusline+=\                          " Space.
  set statusline+=%{statusline#sneaking()}
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

  set statusline+=%([%R%{statusline#ft()}%{statusline#fenc()}]%)
  set statusline+=%*   " Reset highlight group.
  set statusline+=%=   " Split point for left and right groups.

  set statusline+=%{statusline#wc()}
  set statusline+=%([%{&spell?&spelllang:''}%{statusline#jobs()}]%)
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
  set statusline+=%P   " Percentage through buffer.
  set statusline+=\    " Space.
  set statusline+=%*   " Reset highlight group.
endif
