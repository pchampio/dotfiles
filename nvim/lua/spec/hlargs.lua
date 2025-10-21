---@module 'lazy'
---@type LazySpec
local M = {
  'm-demare/hlargs.nvim',
  event = { 'CmdlineEnter', 'CursorHold' },
  opts = {
    color = '#05a4ee',
    hl_priority = 200,
    disable = function(_, bufnr)
      return vim.bo.filetype == "bigfile"
    end,
  },
}

return M
