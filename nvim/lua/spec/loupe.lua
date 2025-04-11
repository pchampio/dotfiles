local M = {
  'miallo/loupe',
  event = { 'CmdlineEnter', 'CursorHold' },
  keys = {
    {
      '<leader><space>',
      '<Plug>(LoupeClearHighlight)',
      desc = 'Clear Search Highlight (Loupe)',
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
