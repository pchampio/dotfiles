---@module 'lazy'
---@type LazySpec
local M = {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    branch = 'main',
    build = ':TSUpdate',
    dependencies = {},
    config = function()
      require('nvim-treesitter').setup {
        -- A list of parser names, or 'all' (the five listed parsers should always be installed)
        ensure_installed = {
          'html',
          'css',
          'javascript',
          'tsx',
          'cmake',
          'make',
          'cpp',
          'bash',
          'python',
          'go',
          'java',
          'yaml',
          'sql',
        },

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = false,

        -- Automatically install missing parsers when entering buffer
        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
        auto_install = true,

        -- List of parsers to ignore installing (or 'all')
        ignore_install = {},
        modules = {},

        highlight = {
          enable = true,

          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          -- additional_vim_regex_highlighting = false,
        },
        -- ,
        incremental_selection = { enable = false },
        indent = { enable = true },
      }

      vim.opt.foldenable = false -- Disable folding at startup.
    end,
  },
  {
    'Wansmer/treesj',
    keys = {
      { 'gJ', '<cmd>TSJToggle<cr>', desc = '  Join Toggle' },
      { 'gS', '<cmd>TSJSplit<cr>', desc = '  Join Split' },
    },
    opts = { use_default_keymaps = false, max_join_length = 1000 },
  },
  { 'nvim-treesitter/nvim-treesitter-context', opts = { max_lines = 1 } },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = {
          enable = true,
          include_surrounding_whitespace = false,
        },
        swap = {
          enable = true,
        },
        move = {
          enable = true,
          set_jumps = true,
        },
      }

      vim.keymap.set({ "x", "o" }, "af", function() require "nvim-treesitter-textobjects.select".select_textobject("@function.outer", "textobjects") end, { desc = '󱘎  around function' })
      vim.keymap.set({ "x", "o" }, "if", function() require "nvim-treesitter-textobjects.select".select_textobject("@function.inner", "textobjects") end, { desc = '󱘎  inner function' })
      vim.keymap.set({ "x", "o" }, "am", function() require "nvim-treesitter-textobjects.select".select_textobject("@class.outer", "textobjects") end, { desc = '󱘎  inner class' })
      vim.keymap.set({ "x", "o" }, "im", function() require "nvim-treesitter-textobjects.select".select_textobject("@class.inner", "textobjects") end, { desc = '󱘎  inner class' })
      vim.keymap.set({ "x", "o" }, "ia", function() require "nvim-treesitter-textobjects.select".select_textobject("@parameter.inner", "textobjects") end, { desc = '󱘎  inner param' })
      vim.keymap.set({ "x", "o" }, "aa", function() require "nvim-treesitter-textobjects.select".select_textobject("@parameter.outer", "textobjects") end, { desc = '󱘎  around param' })
      vim.keymap.set({ "x", "o" }, "ac", function() require "nvim-treesitter-textobjects.select".select_textobject("@conditional.outer", "textobjects") end, { desc = '󱘎  around conditional' })
      vim.keymap.set({ "x", "o" }, "ic", function() require "nvim-treesitter-textobjects.select".select_textobject("@conditional.inner", "textobjects") end, { desc = '󱘎  inner conditional' })
      vim.keymap.set({ "x", "o" }, "il", function() require "nvim-treesitter-textobjects.select".select_textobject("@call.inner", "textobjects") end, { desc = '󱘎  inner call' })
      vim.keymap.set({ "x", "o" }, "aH", function() require "nvim-treesitter-textobjects.select".select_textobject("@assignment.lhs", "textobjects") end, { desc = '󱘎  assignment lhs' })
      vim.keymap.set({ "x", "o", "n" }, "]f", function() require "nvim-treesitter-textobjects.move".goto_next_start("@function.outer", "textobjects") end, { desc = '󱘎  Move To Next Function' })
      vim.keymap.set({ "x", "o", "n" }, "[f", function() require "nvim-treesitter-textobjects.move".goto_previous_start("@function.outer", "textobjects") end, { desc = '󱘎  Move To Previous Function' })
      vim.keymap.set({ "x", "o", "n" }, "[F", function() require "nvim-treesitter-textobjects.move".goto_next_start("@function.outer", "textobjects") end, { desc = '_󱘎  Move To Next Function' })
      vim.keymap.set({ "x", "o", "n" }, "]F", function() require "nvim-treesitter-textobjects.move".goto_previous_start("@function.outer", "textobjects") end, { desc = '_󱘎  Move To Previous Function' })
      -- TODO: class next
      vim.keymap.set({ "x", "o", "n" }, "]m", function() require "nvim-treesitter-textobjects.move".goto_next_start("@class.outer", "textobjects") end, { desc = '󱘎  Move To Next Method' })
      vim.keymap.set({ "x", "o", "n" }, "[m", function() require "nvim-treesitter-textobjects.move".goto_previous_start("@class.outer", "textobjects") end, { desc = '󱘎  Move To Previous Method' })
      vim.keymap.set({ "x", "o", "n" }, "[M", function() require "nvim-treesitter-textobjects.move".goto_next_start("@class.outer", "textobjects") end, { desc = '_󱘎  Move To Next Method' })
      vim.keymap.set({ "x", "o", "n" }, "]M", function() require "nvim-treesitter-textobjects.move".goto_previous_start("@class.outer", "textobjects") end, { desc = '_󱘎  Move To Previous Method' })

      vim.keymap.set("n", "<A-.>", function() require("nvim-treesitter-textobjects.swap").swap_next "@parameter.inner" end)
      vim.keymap.set("n", "<A-,>", function() require("nvim-treesitter-textobjects.swap").swap_previous "@parameter.inner" end)

    end,
  },
}

return M
