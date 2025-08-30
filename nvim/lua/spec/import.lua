local M = {
  'piersolenski/import.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    picker = 'telescope',
    insert_at_top = true,
  },
  keys = {
    {
      '<leader>I',
      function()
        require('import').pick()
      end,
      desc = 'Import',
    },
  },
}

return M
