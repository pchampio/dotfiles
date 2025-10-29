---@module 'lazy'
---@type LazySpec
local M = {
  'miallo/loupe',
  event = { 'CmdlineEnter', 'CursorHold' },
  keys = {
    { '<NOP>', '<Plug>(LoupeGOctothorpe)', desc = '  Search backwards word under cursor' },
    { 'g*', '<Plug>(LoupeGStar)', desc = '  Search word under cursor' },
    {
      '<leader><space>',
      function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Plug>(LoupeClearHighlight)', true, true, true), 'n', false)
        local ok, sidekick = pcall(require, 'sidekick.nes')
        if ok and sidekick.clear then
          sidekick.clear()
        end
      end,
      desc = '  Clear Search/Nes',
    },
  },
  init = function()
    -- the fork
    vim.g.LoupeVeryMagicReplace = 1
    -- Not needed in Neovim (see `:help hl-CurSearch`).
    vim.g.LoupeHighlightGroup = ''
    vim.g.LoupeClearHighlightMap = 0 -- Avoid mapping conflicts
  end,
}

return M
