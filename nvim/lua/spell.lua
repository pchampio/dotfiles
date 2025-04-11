-- autocmd to set spell-checking, language, and textwidth for Markdown files
vim.cmd [[autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en tw=80]]

vim.cmd [[hi SpellBad gui=underline guifg=#dc322f]]
vim.cmd [[hi SpellCap gui=undercurl guifg=#6c71c4]]
vim.cmd [[hi SpellRare gui=undercurl guifg=#6c71c4]]
vim.cmd [[hi SpellLocal gui=undercurl guifg=#eee8d5]]

vim.o.spellfile = vim.fn.expand '~/dotfiles/spell/ownSpellFile.utf-8.add'
