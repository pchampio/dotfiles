local M = {
  -- keep an eye on where your cursor has jumped
  'cxwx/specs.nvim',
  lazy = true,
  event = 'CursorMoved',
  config = function()
    require('specs').setup {
      show_jumps = true,
      min_jump = 10,
      popup = {
        delay_ms = 0, -- delay before popup displays
        inc_ms = 10, -- time increments used for fade/resize effects
        blend = 10, -- starting blend, between 0-100 (fully transparent), see :h winblend
        width = 20,
        winhl = 'PmenuSbar',
        fader = require('specs').pulse_fader,
        resizer = require('specs').shrink_resizer,
      },
      ignore_filetypes = {},
      ignore_buftypes = { nofile = true },
    }
  end,
}

return M
