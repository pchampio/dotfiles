function my_toggles()
  Snacks.toggle.inlay_hints({ name = 'Inlay Hints ' }):map '<leader>th'
  Snacks.toggle.line_number({ name = 'Line Numbers ' }):map '<leader>tl'
  Snacks.toggle.option('wrap', { name = 'Wrap Lines ' }):map '<leader>tw'
  Snacks.toggle.words():map '<leader>tu'
  Snacks.toggle.new ({
    id = 'toggle_format', name = 'Auto format ',
    get = function() return vim.g.toggle_auto_format or false end,
    set = function(state)
      vim.g.toggle_auto_format = state
    end,
  }):map '<leader>tf'
  Snacks.toggle.new ({
    id = 'blame_line', name = 'current line blame  ',
    get = function() return vim.g.toogle_blame_line or false end,
    set = function(state)
      vim.g.toogle_blame_line = state
      require 'gitsigns'.toggle_current_line_blame()
    end,
  }):map '<leader>tb'
  Snacks.toggle.new ({
    id = 'line_word_diff', name = 'word diff  ',
    get = function() return vim.g.toogle_word_diff or false end,
    set = function(state)
      vim.g.toogle_word_diff = state
      require 'gitsigns'.toggle_word_diff()
    end,
  }):map '<leader>td'
  Snacks.toggle.new ({
    id = 'spell_en', name = 'English Spelling 󰓆 ',
    get = function() return vim.g.toogle_en_spell or false end,
    set = function(state)
      vim.g.toogle_en_spell = state
      vim.cmd 'setlocal spell! spelllang=en'
    end,
  }):map '<leader>tSe'
  Snacks.toggle.new ({
    id = 'spell_all', name = 'All Lang Spelling 󰓆 ',
    get = function() return vim.g.toogle_all_spell or false end,
    set = function(state)
      vim.g.toogle_all_spell = state
      vim.cmd 'setlocal spell! spelllang=en,fr'
    end,
  }):map '<leader>tSa'
  Snacks.toggle.new ({
    id = 'spell_fr', name = 'French Spelling 󰓆 ',
    get = function() return vim.g.toogle_fr_spell or false end,
    set = function(state)
      vim.g.toogle_fr_spell = state
      vim.cmd 'setlocal spell! spelllang=fr'
    end,
  }):map '<leader>tSf'
end

local M = {
  'folke/snacks.nvim',
  dependencies = {
    "folke/todo-comments.nvim",
    config = function()
      local todocomments = require 'todo-comments'
      todocomments.setup()

      vim.keymap.set('n', ']t', function()
        todocomments.jump_next()
      end, { desc = 'Next todo comment' })

      vim.keymap.set('n', '[t', function()
        todocomments.jump_prev()
      end, { desc = 'Previous todo comment' })
    end,
  },
  priority = 1000,
  lazy = false,
  keys = {
    { '<leader>hB', function() Snacks.gitbrowse() end,                    desc = ' Open Browser' },
    { '<leader>hb', function() Snacks.git.blame_line() end,               desc = ' Blame Line' },
    { '<leader>nd', function() Snacks.notifier.hide() end,                desc = 'Notif Dismiss All' },
    { '<leader>np', function() Snacks.notifier.show_history() end,        desc = 'Notif Preview' },

    { "gd",         function() Snacks.picker.lsp_definitions() end,       desc = "LSP: Goto Definition" },
    { "gD",         function() Snacks.picker.lsp_declarations() end,      desc = "LSP: Goto Declaration" },
    { "gr",         function() Snacks.picker.lsp_references() end,        nowait = true, desc = "LSP: References" },
    { "gI",         function() Snacks.picker.lsp_implementations() end,   desc = "LSP: Goto Implementation" },
    { "gt",         function() Snacks.picker.lsp_type_definitions() end,  desc = "LSP: Goto Type Definition" },
    { "<leader>gs", function() Snacks.picker.lsp_symbols() end,           desc = "LSP: Symbols" },
    { "<leader>gS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP: Workspace Symbols" },
    { "<leader>gd", function() Snacks.picker.diagnostics_buffer() end, desc = "LSP: ⚑ Diagnostics in Buffer" },
    { "<leader>gD", function() Snacks.picker.diagnostics() end, desc = "LSP: ⚑ Diagnostics in Project" },

    { "ga", '<cmd>lua vim.lsp.buf.code_action()<cr>', desc = "LSP: code actions" },
    { "g=", function() vim.lsp.buf.format { async = true } end, desc = "LSP: format selection or buffer", mode = { "v", "n" } },
    { "gh", vim.lsp.buf.hover, desc = 'LSP: Hover', mode = { "v", "n" } },

    { "<leader>ut", function() Snacks.picker.undo() end,                  desc = "Undo tree" },
    { '<leader>P', function() Snacks.picker.yanky() end, mode = { 'n', 'x' }, desc = 'Open Yank History' },


    { "]w",         function() Snacks.words.jump(vim.v.count1) end,       desc = "Next Reference",           mode = { "n", "t" } },
    { "[w",         function() Snacks.words.jump(-vim.v.count1) end,      desc = "Prev Reference",           mode = { "n", "t" } },

    { "<leader>to", function () Snacks.picker.todo_comments({ keywords = { "TODO", "HACK", "WARNING", "BUG", "NOTE", "INFO", "PERF", "ERROR" } }) end, desc = "Todo Comment Tags" },
  },
  config = function()

      -- Disable the default keybinds
      for _, bind in ipairs { 'grn', 'gra', 'gri', 'grr', 'grt' } do
        pcall(vim.keymap.del, 'n', bind)
      end


    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = my_toggles
    })

    vim.api.nvim_create_autocmd({ 'LspAttach' }, {
      pattern = { '*' },
      callback = function()
        vim.api.nvim_set_hl(0, 'LspReferenceText', { underline = true })
        vim.api.nvim_set_hl(0, 'LspReferenceRead', { underline = true })
        vim.api.nvim_set_hl(0, 'LspReferenceWrite', { underline = true })
      end,
    })

    local layouts = require 'snacks.picker.config.layouts'
    layouts.my_ivylayout = {
      preview = false,
      layout = {
        box = 'vertical',
        backdrop = false,
        row = -1,
        width = 0,
        height = 0.4,
        border = 'top',
        title = ' {title} {live} {flags}',
        title_pos = 'left',
        {
          box = 'horizontal',
          { win = 'list',    border = 'none' },
          { win = 'preview', title = '{preview}', width = 0.7, border = 'left' },
        },
        { win = 'input', height = 1, border = 'single' },
      },
    }

    require('snacks').setup {
      rename = { enabled = true },
      toggle = {},
      bigfile = { enabled = true },
      words = { enabled = true, debounce = 100 },
      notifier = {
        enabled = true,
        timeout = 1000,
      },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },

      indent = {
        enabled = true,
        indent = {
          enabled = true,
          char = "▏",
        },
        scope = {
          enabled = true,       -- enable highlighting the current scope
          char = "▏",
          underline = false,    -- underline the start of the scope
          only_current = false, -- only show scope in the current window
          hl = "SnacksIndent1", ---@type string|string[] hl group for scopes
        },
        animate = {
          style = "out",
          easing = "linear",
          duration = {
            step = 15,   -- ms per step
            total = 150, -- maximum duration
          },
        },
        -- filter for buffers to enable indent guides
        filter = function(buf)
          local excluded_filetypes = {
            markdown = true,
            diff = true,
            text = true,
          }
          local b = vim.b[buf]
          local bo = vim.bo[buf]
          return vim.g.snacks_indent ~= false
              and b.snacks_indent ~= false
              and bo.buftype == ""
              and not excluded_filetypes[bo.filetype]
        end,
      },
      picker = {
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
        },
        prompt = "> ",
        layout = { preset = "my_ivylayout" },
        ui_select = false,
        win = {
          input = {
            keys = {
              ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
              ['<C-j>'] = { 'list_down', mode = { 'i', 'n' } },
              ['<C-k>'] = { 'list_up', mode = { 'i', 'n' } },
              ["<Tab>"] = { "edit_split", mode = { "i", "n" } },
              ['<C-s>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
              ["<C-z>"] = { "select_and_next", mode = { "i", "n", "x" } },
              ["<C-l>"] = { "toggle_preview", mode = { "i", "n", "x" } },
              ["<C-h>"] = { "toggle_preview", mode = { "i", "n", "x" } },
              ["<C-P>"] = { "toggle_preview", mode = { "i", "n", "x" } },
              ["<C-p>"] = { "list_up", mode = { "i", "n" } },
            },
          },
        },
      }
    }
    vim.api.nvim_create_autocmd('User', {
      pattern = 'OilActionsPost',
      callback = function(event)
        if event.data.actions.type == 'move' then
          Snacks.rename.on_rename_file(
            event.data.actions.src_url,
            event.data.actions.dest_url
          )
        end
      end,
    })
  end,
}
return M
