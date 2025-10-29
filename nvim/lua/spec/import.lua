---@module 'lazy'
---@type LazySpec
local M = {
  {
    'piersolenski/import.nvim',
    dependencies = { 'folke/snacks.nvim' },
    opts = {
      picker = 'snacks',
      insert_at_top = true,
    },
    keys = { { '<leader>ig', function() require('import').pick() end, desc = '󱙾  Import Generic Picker' } },
  },
  -- { -- TODO: Delete this plugin later if the AbysmalBiscuit's one works better.
  --   "Davidyz/inlayhint-filler.nvim",
  --   keys = {
  --     { "<Leader>ih", function() require("inlayhint-filler").fill() end, desc = "Insert Inlay-Hint", mode = { "n", "v" } },
  --   },
  -- },
  {
    "AbysmalBiscuit/insert-inlay-hints.nvim",
    keys = {
      { "<leader>ih", function() require("insert-inlay-hints").closest() end, desc = "Insert Closest Inline Hint" },
      { "<leader>il", function() require("insert-inlay-hints").line() end, desc = "Insert Line Inline Hints" },
      { "<leader>i", function() require("insert-inlay-hints").visual() end, desc = "Insert Visual Inlay Hints", mode = { "v" } },
      { "<leader>ia", function() return require("insert-inlay-hints").all() end, desc = "Insert All Inlay Hints" },
    },
  },
  {
    'kiyoon/python-import.nvim',
    ft = { 'python' },
    build = 'python3 -m pipx install . --force',
    keys = {
      { '<leader>ip', function() require('python_import.api').add_import_current_word_and_notify() end, mode = { 'i', 'n' }, silent = true, desc = '󱙾  Import Python Word', ft = 'python' },
    },
    opts = {
      extend_lookup_table = {
        ---@type string[]
        import = {
          'tqdm',
        },

        ---@type table<string, string>
        import_as = {
          np = 'numpy',
          pd = 'pandas',
        },

        ---@type table<string, string>
        import_from = {
          tqdm = 'tqdm',
        },
      },
    },
  },
}

return M
