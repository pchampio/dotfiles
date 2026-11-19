-- The native terminal bridge works locally and through an existing SSH shell.
-- Do not load smart-splits' wezterm CLI adapter against this custom GUI.
if vim.env.REX_SERVER or not vim.env.TMUX then
  vim.g.smart_splits_multiplexer_integration = false
  return {
    dir = vim.fn.stdpath('config') .. '/local/rex-splits.nvim',
    name = 'rex-splits.nvim',
    lazy = false,
    opts = { default_amount = 6 },
    config = function(_, opts) require('rex_splits').setup(opts) end,
  }
end

---@module 'lazy'
---@type LazySpec
return {
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
