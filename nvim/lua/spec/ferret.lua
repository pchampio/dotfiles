local M = {
  'wincent/ferret',
  keys = {
    { '<leader>*', '<Plug>(FerretAckWord)', desc = '[*] Seach word all files' },
    {
      '<leader>E',
      '<Plug>(FerretAcks)',
      desc = '[E] Edit searched word all files',
    },
    {
      'g/',
      ':Ack<space>',
      desc = '[/] Input word search all files',
    },
  },
  config = function()
    vim.g['FerretExecutableArguments'] = {
      rg = '--vimgrep --no-heading --max-columns 4096',
    }
  end,
}

return M
