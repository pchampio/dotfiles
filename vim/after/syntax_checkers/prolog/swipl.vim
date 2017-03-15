"============================================================================
"File:        swipl.vim
"Description: Syntax checking plugin for syntastic.vim
"Maintainer:  Zaki Mughal <zaki.mughal@gmail.com>,
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================
"
" Checker options:
"
" - g:syntastic_swipl_interpreter (string; default: 'swipl')
"   The SWI-Prolog interpreter to use.
"
if exists('g:loaded_syntastic_prolog_swipl_checker')
    finish
endif
let g:loaded_syntastic_prolog_swipl_checker=1

if !exists('g:syntastic_swipl_interpreter')
    let g:syntastic_swipl_interpreter = 'swipl'
endif

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_prolog_swipl_IsAvailable() dict
    silent! call system(syntastic#util#shexpand(g:syntastic_prolog_interpreter) . ' -qt ' . syntastic#util#shescape('halt'))
    return v:shell_error == 0
endfunction

function! SyntaxCheckers_prolog_swipl_Preprocess(errors)
    let out = []

    " for e in a:errors
        " call add(out, e)
    " endfor

    return syntastic#util#unique(out)
endfunction

function! SyntaxCheckers_prolog_swipl_GetLocList() dict
    let exe = expand(g:syntastic_swipl_interpreter)
    let errorformat = 'ERROR: %f:%l:%c:%m,'
    " let errorformat .= 'Warning: %f:%l:'

    let makeprg = self.makeprgBuild({
        \ 'exe': exe,
        \ 'args_before': '-q -t halt -s ' })

    let errors = SyntasticMake({
        \ 'makeprg': makeprg,
        \ 'errorformat': errorformat,
        \ 'defaults': {'type': 'E'} })
        " 'preprocess': 'SyntaxCheckers_prolog_swipl_Preprocess',
    return errors
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'prolog',
    \ 'name': 'swipl'})

let &cpo = s:save_cpo
unlet s:save_cpo

" Example errors:
"
" Warning: file.pl:128:
"         Singleton variables: [Var0,Var1,Var2]
" ERROR: file.pl:259:8: Syntax error: Operator expected
"
" the ERROR is on a specific line
" The singleton warning is for a specific Prolog rule


" vim: set et sts=4 sw=4:
