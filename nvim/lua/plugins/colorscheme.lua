---@module 'lazy'
---@type LazySpec
return {
  'https://gitlab.com/HiPhish/resolarized.nvim',
  lazy = false,
  priority = 10000,
  config = function()
    vim.cmd [[colorscheme selenized-light]]
    vim.o.background = 'light'
  end,
}
