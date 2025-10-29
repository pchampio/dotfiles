local M = {
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'LspAttach',
    config = function()
      require('tiny-inline-diagnostic').setup {
        -- Main options configuration
        options = {
          throttle = 0, -- No throttle for immediate cursor response
          severity = {
            vim.diagnostic.severity.WARN,
            vim.diagnostic.severity.ERROR,
          },
          -- Multiline diagnostic configuration
          multilines = {
            enabled = true, -- Enable multiline diagnostics
            always_show = true, -- Show all lines when cursor is on diagnostic line
            trim_whitespaces = true, -- Clean up whitespace
            tabstop = 4, -- Convert tabs to 4 spaces
            severity = { vim.diagnostic.severity.ERROR },
          },
        },
      }
    end,
  },
  {
    'rachartier/tiny-code-action.nvim',
    config = function()
      require('tiny-code-action').setup {
        -- backend = 'diffsofancy',
        picker = {
          'snacks',
          opts = {
            layout = 'my_big_ivylayout_vertical',
          },
        },
      }
    end,
  },
}

return M
