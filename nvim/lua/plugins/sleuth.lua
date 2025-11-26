---@module 'lazy'
---@type LazySpec
return {
  {
     -- Heuristically set buffer options
     event = 'VeryLazy',
    'tpope/vim-sleuth',
  },
  {
    'andymass/vim-matchup',
    lazy = false,
    keys = {
      { '%', '<Plug>(matchup-%)', desc = 'Matchup forward' },
    },
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = 'status_manual' }
      vim.g.matchup_motion_enabled = true
      vim.g.matchup_text_obj_enabled = true
      vim.g.matchup_surround_enabled = false
    end,
  },
}
