---@module 'lazy'
---@type LazySpec
return {{
  'whiteinge/diffconflicts',
  cmd = 'DiffConflicts',
},
{
  "esmuellert/vscode-diff.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      local config = require('vscode-diff.config')
      config.setup({
        highlights = {
            line_insert = '#c5ebb2',
            line_delete = '#f5c2bf',
            char_insert = '#91cc74',
            char_delete = '#f58982',
          },
        })
      local render = require('vscode-diff.render')
      render.setup_highlights()
    end,
}
}

          -- highlights = {
          --   line_insert = '#d2ffd2',
          --   line_delete = '#ffd7d5',
          --   char_insert = '#acf2bd',
          --   char_delete = '#fdb8c0',
          -- },
