"Description: Syntax checking plugin for w0rp/ale
"Language:    Prolog
"Maintainers: Sylvain Soliman <Sylvain.Soliman@inria.fr>
"Last Change: 2017 May 31


function! ale_linters#prolog#prolog#Handle(buffer, lines) abort
   " matches lines like:
   "
   " ERROR: blabla.pl:166:18: Syntax error: Operator expected
   " Warning: blabla.pl:36:
   "        Singleton variables: [A,B]
   let l:pattern = '\(.\)[^:]\+: [^:]\+:\(\d\+\):\(\d\+\): \(.\+\)$'
   let l:output = []
   let l:joined_lines = []
   let l:join = '0: '

   for l:line in a:lines
      if l:line[0] == '	'
         let l:joined_lines[-1] .= l:join . l:line[1:]
         let l:join = ', '
      else
         call add(l:joined_lines, l:line)
         let l:join = '0: '
      endif
   endfor

   for l:match in ale#util#GetMatches(l:joined_lines, l:pattern)
      call add(l:output, {
               \ 'lnum': l:match[2] + 0,
               \ 'col': l:match[3] + 0,
               \ 'text': l:match[4],
               \ 'type': l:match[1],
               \})
   endfor

   return l:output
endfunction


call ale#linter#Define('prolog', {
         \ 'name': 'swipl',
         \ 'executable': 'swipl',
         \ 'command': 'swipl -s %t -q -t halt',
         \ 'output_stream': 'stderr',
         \ 'callback': 'ale_linters#prolog#prolog#Handle'
         \})
