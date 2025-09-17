local M = {
  'monaqa/dial.nvim',
  keys = {
    { '<C-x>', '<Plug>(dial-decrement)', mode = 'n' },
    { '<C-a>', '<Plug>(dial-increment)', mode = 'n' },
  },
  config = function()
    local augend = require 'dial.augend'
    require('dial.config').augends:register_group {
      default = {
        augend.integer.alias.decimal_int, -- nonnegative decimal number (0, 1, 2, 3, ...)
        augend.constant.alias.bool, -- boolean value (true <-> false)
        augend.date.alias['%Y/%m/%d'], -- date (2022/02/19, etc.)
        augend.constant.new {
          elements = { 'true', 'false' },
          preserve_case = true,
        },
      },
    }
    require('dial.config').augends:on_filetype {} -- for specific languages
  end,
}

return M
