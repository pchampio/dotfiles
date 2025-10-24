---@module 'lazy'
---@type LazySpec
local M = {
  'junegunn/vim-easy-align',
  on = { '<Plug>(EasyAlign)', 'EasyAlign' },
  dependencies = 'tpope/vim-repeat',
  keys = {
    { '<leader>A', '<Plug>(EasyAlign)', mode = { 'n', 'x' }, desc = 'EZ Align Text' },
  },
}
return M
