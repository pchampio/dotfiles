local map = require('commons').utils.map

-- [[ Spell check ]]
-- Add word to the spelling dictionary
map('n', '<leader>sa', '<Esc>zg', { desc = '󰓆 Add word to the spelling dictionary' })
-- Remove word from the spelling dictionary
map('n', '<leader>sr', '<Esc>zug', { desc = '󰓆 Remove word from the spelling dictionary' })

-- autocmd to set spell-checking, language, and textwidth for Markdown files
vim.cmd [[autocmd BufRead,BufNewFile *.md setlocal spell spelllang=fr,en tw=80]]

vim.cmd [[hi SpellBad gui=undercurl guifg=#dc322f]]
vim.cmd [[hi SpellCap gui=undercurl guifg=#6c71c4]]
vim.cmd [[hi SpellRare gui=undercurl guifg=#6c71c4]]
vim.cmd [[hi SpellLocal gui=undercurl guifg=#eee8d5]]

vim.o.spellfile = vim.fn.expand '~/dotfiles/spell/ownSpellFile.utf-8.add'
