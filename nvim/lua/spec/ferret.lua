---@module 'lazy'
---@type LazySpec
local M = {
  'wincent/ferret',
  keys = {
    { '<leader>*', '<Plug>(FerretAckWord)', desc = '  * Seach Word All Files' },
    {
      '<leader>E',
      '<Plug>(FerretAcks)',
      desc = '  Edit Searched Word All Files',
    },
    {
      'g/',
      ':Ack<space>',
      desc = '  Word Search All Files',
    },
  },
  config = function()
    vim.g['FerretExecutableArguments'] = {
      rg = '--vimgrep --no-heading --max-columns 4096',
    }
  end,
}

return M
