---@module 'lazy'
---@type LazySpec
local M = {
  'mrjones2014/smart-splits.nvim',
  opts = { default_amount = 6, disable_multiplexer_nav_when_zoomed = false },
  keys = {
    {
      '<C-h>',
      function()
        require('smart-splits').move_cursor_left()
      end,
      desc = '[h] Move cursor left pane',
    },
    {
      '<C-j>',
      function()
        require('smart-splits').move_cursor_down()
      end,
      desc = '[j] Move cursor down pane',
    },
    {
      '<C-k>',
      function()
        require('smart-splits').move_cursor_up()
      end,
      desc = '[k] Move cursor up pane',
    },
    {
      '<C-l>',
      function()
        require('smart-splits').move_cursor_right()
      end,
      desc = '[l] Move cursor right pane',
    },
  },
}

return M
