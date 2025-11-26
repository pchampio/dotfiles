---@module 'lazy'
---@type LazySpec
return {
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

  version = '*', -- Remove if you DON'T want to use the stable version
}
