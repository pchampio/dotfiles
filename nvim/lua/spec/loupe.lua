---@module 'lazy'
---@type LazySpec
local M = {
  'miallo/loupe',
  event = { 'CmdlineEnter', 'CursorHold' },
  keys = {
    {
      '<leader><space>',
      function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Plug>(LoupeClearHighlight)', true, true, true), 'n', false)
        local ok, sidekick = pcall(require, 'sidekick.nes') -- TODO: make this work, as of now only <esc> works
        if ok and sidekick.clear then
          sidekick.clear()
        end
      end,
      desc = ' Clear Search Hi/Nes suggestions',
    },
  },
  init = function()
    -- the fork
    vim.g.LoupeVeryMagicReplace = 1
    -- Not needed in Neovim (see `:help hl-CurSearch`).
    vim.g.LoupeHighlightGroup = ''
  end,
}

return M
