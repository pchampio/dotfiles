---@module 'lazy'
---@type LazySpec
local M = {
  'tpope/vim-sleuth',
  {
    'andymass/vim-matchup',
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = 'popup' }
      vim.g.matchup_motion_enabled = true
      vim.g.matchup_text_obj_enabled = true
      vim.g.matchup_surround_enabled = false
    end,
  },
}

return M
