---@module 'lazy'
---@type LazySpec
local M = {
  'rachartier/tiny-inline-diagnostic.nvim',
  event = 'VeryLazy', -- Or `LspAttach`
  priority = 1000, -- Needs to be loaded in first
  config = function()
    require('tiny-inline-diagnostic').setup()
  end,
}

return M
