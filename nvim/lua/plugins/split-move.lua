-- Ctrl-h/j/k/l move between nvim splits, and past the edge to the next pane
-- of the terminal (WezTerm and Rex, also through SSH): rex-splits.nvim.
-- smart-splits' wezterm CLI adapter must not load against this custom GUI.
vim.g.smart_splits_multiplexer_integration = false
return {
  dir = vim.fn.stdpath('config') .. '/local/rex-splits.nvim',
  name = 'rex-splits.nvim',
  lazy = false,
  opts = { default_amount = 6 },
  config = function(_, opts) require('rex_splits').setup(opts) end,
}
