local ensure_installed = {
  'html',
  'css',
  'javascript',
  'cmake',
  'make',
  'cpp',
  'bash',
  'python',
  'go',
  'java',
  'yaml',
  'sql',
}

---@module 'lazy'
---@type LazySpec
return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    branch = 'main',
    build = function()
      require('nvim-treesitter').install(ensure_installed)
      require('nvim-treesitter').update()
    end,
    dependencies = {},
    config = function()
      require('nvim-treesitter').install(ensure_installed):await(function()
        vim.api.nvim_create_autocmd('FileType', {
          callback = function(args)
            local filetype = args.match
            local lang = vim.treesitter.language.get_lang(filetype)
            if vim.treesitter.language.add(lang) then
              vim.wo.foldmethod = 'expr'
              vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
              vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              vim.treesitter.start()
            end
          end,
        })
      end)
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
  { event = 'VeryLazy', 'nvim-treesitter/nvim-treesitter-context', opts = { max_lines = 2 } },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    event = 'VeryLazy',
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


{ 'Yggdroot/LeaderF',                 build = './install.sh' },
}
