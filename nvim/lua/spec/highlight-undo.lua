local M = {
  'tzachar/highlight-undo.nvim',
  enable = false,
  opts = {
    ignore_cb = function(bufnr)
      return require('commons').utils.isBufSizeBig(bufnr)
    end,
  },
}

return M
