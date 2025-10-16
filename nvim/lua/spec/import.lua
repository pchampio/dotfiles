local M = {
  'piersolenski/import.nvim',
  dependencies = {
    'folke/snacks.nvim',
  },
  opts = {
    picker = 'snacks',
    insert_at_top = true,
  },
  keys = { { '<leader>I', function() require('import').pick() end, desc = '󱙾 Import Picker' } },
}

return M
