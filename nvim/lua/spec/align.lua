local M = {
  'junegunn/vim-easy-align',
  on = { '<Plug>(EasyAlign)', 'EasyAlign' },
  dependencies = 'tpope/vim-repeat',
  keys = {
    { '<leader>ga', '<Plug>(EasyAlign)', mode = { 'n', 'x' }, desc = 'Align' },
  },
}
return M
