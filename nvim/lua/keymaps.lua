local map = require('commons').utils.map

-- Save the file with leader-leader mapping
map('n', '<leader><leader>', [[:w!<CR>]], { desc = '󰽃  ,Save file' })

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

map('n', '<leader>r', '<Esc>:call RenameFile()<CR>', { desc = '󰑕  RenameFile' })

-- Disable the default keybinds
for _, bind in ipairs {
  'grn',
  'gra',
  'gri',
  'grr',
  'grt',
  'gO',
  '<c-w>d',
  '<c-w><c-d>',
} do
  pcall(vim.keymap.del, 'n', bind)
end

map('n', '<leader>d', vim.diagnostic.open_float, { desc = '⚑  Diagnostic show' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, { desc = '⚑  Jump To Diagnostic' })
map('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, { desc = '⚑  Jump To Diagnostic' })

-- Spell check correct
vim.cmd [[
inoremap <expr> <A-s>  pumvisible() ?  "\<C-n>" : "\<C-x>s"
nnoremap <expr> <A-s> pumvisible() ?  "i\<C-n>" : "w[sei\<C-x>s"
]]

map({'n', 'v'}, 'gA', 'ga', { desc = 'Get Char Ascii Value' })

-- Leader mapping to change working directory to the current file's directory
map('n', '<leader>cd', function()
  local dir = vim.fn.expand '%:p:h'
  -- Enter command-line mode and insert the lcd command
  vim.api.nvim_feedkeys(':' .. 'lcd ' .. dir, 'n', false)
  require('wincent.commandt').setup({ traverse = 'none' })
end, { desc = '  Change Directory', silent = false })
