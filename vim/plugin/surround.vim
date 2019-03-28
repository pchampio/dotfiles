let g:sandwich_no_default_key_mappings = 1
let g:operator_sandwich_no_default_key_mappings = 1
let g:textobj_sandwich_no_default_key_mappings = 1

nmap S <Plug>(operator-sandwich-add)
onoremap <SID>line :normal! ^vg_<CR>
nmap <silent> SS <Plug>(operator-sandwich-add)<SID>line
onoremap <SID>gul g_

nmap ds <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
nmap dss <Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)
nmap cs <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)
nmap css <Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)

xmap S <Plug>(operator-sandwich-add)

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

let g:sandwich#recipes = deepcopy(g:sandwich#default_recipes)
" Insert mode for function addition
" F for matching class.method(____)
let g:sandwich#recipes += [
  \   {
  \     'buns': ['(', ')'],
  \     'cursor': 'head',
  \     'command': ['startinsert'],
  \     'kind': ['all'],
  \     'action': ['add'],
  \     'input': ['f']
  \   },
  \
  \   {
  \     'buns': ['sandwich#magicchar#f#fname()', '")"'],
  \     'kind': ['add', 'replace'],
  \     'action': ['add'],
  \     'expr': 1,
  \     'input': ['g']
  \   },
  \
  \   {
  \     'buns': ['\h\k*\.\h\k*(', ')\s*$'],
  \     'regex': 1,
  \     'kind': ['all'],
  \     'input': ['F']
  \   }
  \ ]

autocmd FileType python call sandwich#util#addlocal([
  \   {'buns': ['"""', '"""'], 'nesting': 0, 'input': ['3"']},
\ ])
