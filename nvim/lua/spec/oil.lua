---@module 'lazy'
---@type LazySpec
local M = {
  'stevearc/oil.nvim',
  dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
  opts = {},
  keys = { { '-', '<CMD>Oil<CR>' } },
  lazy = false,
}
return M
