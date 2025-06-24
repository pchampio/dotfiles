local map = require('commons').utils.map

-- Save the file with leader-leader mapping
map('n', '<leader><leader>', [[:w!<CR>]])

-- Insert new line
map('n', 'U', [[:call append(line('.'), '')<CR>j]])

-- CMD remap
map({ 'n', 'v' }, ';', ':', { silent = false })
vim.cmd [[
cnoreabbrev ; :
cnoremap <C-A> <Home>
]]

-- Repeat dot on visual
map({ 'v' }, '.', ':norm.<CR>')

-- Resizing a window split
map('n', '<S-Left>', '<C-w>10<')
map('n', '<S-Down>', '<C-w>5-')
map('n', '<S-Up>', '<C-w>5+')
map('n', '<S-Right>', '<C-w>10>')

map({ 'n', 'v' }, '<Space>', '<Nop>')

-- Remap for dealing with word wrap
-- map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
-- map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Faster quicklist navigation
map('n', '<Up>', ':cprevious<CR>')
map('n', '<Down>', ':cnext<CR>')
map('n', '<Left>', ':cpfile<CR>')
map('n', '<Right>', ':cnfile<CR>')

-- Quicker navigation start - end of line
map('n', 'H', '0^')
map('x', 'H', '^')
map('o', 'H', '^')
map('n', 'L', 'g_')
map('x', 'L', 'g_')
map('o', 'L', 'g_')

-- Overrides the change operations so they don't affect the current yank
map('n', 'c', '"_c')
map('n', 'C', '"_C')

-- Insert mode mapping for <C-l> to escape and move to the end of the line
map('i', '<C-l>', '<Esc>A')

map('n', '<leader>rm', '<Esc>:call RenameFile()<CR>', { desc = 'RenameFile' })

-- Spell check correct
vim.cmd [[
inoremap <expr> <A-s>  pumvisible() ?  "\<C-n>" : "\<C-x>s"
nnoremap <expr> <A-s> pumvisible() ?  "i\<C-n>" : "w[sei\<C-x>s"
]]

-- [[ Spell check ]]
map(
  'n',
  '<leader>sen',
  '<Esc>:silent setlocal spell! spelllang=en<CR>',
  { desc = '󰓆 Toggle english spell-checking' }
)
map(
  'n',
  '<leader>sfr',
  '<Esc>:silent setlocal spell! spelllang=fr<CR>',
  { desc = '󰓆 Toggle french spell-checking' }
)
map(
  'n',
  '<leader>sall',
  '<Esc>:silent setlocal spell! spelllang=fr,en<CR>',
  { desc = '󰓆 Toggle french/english spell-checking' }
)
-- Add word to the spelling dictionary
map(
  'n',
  '<leader>sa',
  '<Esc>zg',
  { desc = '󰓆 Add word to the spelling dictionary' }
)
-- Remove word from the spelling dictionary
map(
  'n',
  '<leader>sr',
  '<Esc>zug',
  { desc = '󰓆 Remove word from the spelling dictionary' }
)

-- Leader mapping to change working directory to the current file's directory
map(
  'n',
  '<leader>cd',
  '<Esc>:lcd <C-r>=expand("%:p:h")<CR>',
  { desc = '[d] Change current file directory', silent = false }
)
