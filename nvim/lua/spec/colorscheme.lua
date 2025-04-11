local M = {
  'https://gitlab.com/HiPhish/resolarized.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd [[colorscheme selenized-light]]
    vim.o.background = 'light'
  end,
}

return M
