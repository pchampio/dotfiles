-- :h :DiffOrig
vim.api.nvim_create_user_command('DiffOrig', function()
  vim.cmd(
    'vert new | set buftype=nofile | set filetype='
      .. vim.bo.filetype
      .. ' | read ++edit # | 0d_ | diffthis | wincmd p | diffthis'
  )
end, {})

-- CUSTOM viml functions
vim.cmd [[

" Close vim if the quickfix window or other listed window is the only window visible
function! s:CloseOnlyWindow() abort
let s:buftype =  getbufvar(winbufnr(winnr()), "&buftype")
if s:buftype == "quickfix" || &filetype == 'twiggy' || &filetype == 'fzf' || &filetype == 'NvimTree'
if winnr('$') == 1
q
endif
endif
endfunction
"
autocmd WinEnter * call s:CloseOnlyWindow()

" Autocommand to trigger MkNonExDir function before writing the buffer
function! s:MkNonExDir(file, buf) abort
if empty(getbufvar(a:buf, '&buftype')) && a:file!~#'\v^\w+\:\/'
let dir=fnamemodify(a:file, ':h')
if !isdirectory(dir) | call mkdir(dir, 'p') | endif
endif
endfunction
"
augroup BWCCreateDir
autocmd!
autocmd BufWritePre * :call s:MkNonExDir(expand('<afile>'), +expand('<abuf>'))
augroup END

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
]]
