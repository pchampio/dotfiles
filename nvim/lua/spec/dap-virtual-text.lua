local M = {
  'theHamsta/nvim-dap-virtual-text',
  dependencies = {
    {
      'mfussenegger/nvim-dap',
      {
        'nvim-treesitter/nvim-treesitter',
        build = function()
          require('nvim-treesitter.install').update { with_sync = true } ()
        end,
      },
    },
  },
  opts = {},
}

return M
