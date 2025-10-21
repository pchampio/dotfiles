---@module 'lazy'
---@type LazySpec
local M = {
  'andrewferrier/debugprint.nvim',

  dependencies = {
    'folke/snacks.nvim',
  },

  opts = {},
  keys = {
    { 'gv', mode = { 'n', 'x' }, desc = 'Veriable log' },
    { 'gV', mode = { 'n', 'x' }, desc = 'Veriable log above' },
    { 'gp', mode = { 'n', 'x' }, desc = 'Plain debug log below' },
    { 'gP', mode = { 'n', 'x' }, desc = 'Plain debug log below' },
  },

  lazy = false,
  version = '*', -- Remove if you DON'T want to use the stable version
}
return M
