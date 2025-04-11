local M = {
  -- Comment visual regions/lines
  'numToStr/Comment.nvim',
  opts = {
    ignore = '^$',
    toggler = { line = '<leader>c<space>' },
    opleader = { line = '<leader>c<space>' },
    extra = { eol = '<leader>cA', below = '<leader>cU', above = '<leader>cO' },
  },
}

return M
