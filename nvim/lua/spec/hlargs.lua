local M = {
  'm-demare/hlargs.nvim',
  -- event = { 'CmdlineEnter', 'CursorHold' },
  opts = {
    color = '#05a4ee',
     hl_priority = 200,
    disable = function(_, bufnr)
      return require('commons').utils.isBufSizeBig(bufnr)
    end,
  },
}

return M
