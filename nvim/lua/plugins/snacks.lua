local function my_toggles()
  Snacks.toggle.inlay_hints({ id = '[LSP] Inlay Hints', name = '[LSP] Inlay Hints' }):map '<leader>th'
  Snacks.toggle.line_number({ id = '[O] Line Numbers', name = '[O] Line Numbers' }):map '<leader>tl'
  Snacks.toggle.option('wrap', { id = '[O] Wrap Lines', name = '[O] Wrap Lines' }):map '<leader>tw'
  Snacks.toggle.new({
    id = "[LSP] Diagnostics Hints",
    name = "[LSP] Diagnostics Hints",
    get = function() return vim.diagnostic.is_enabled() end,
    set = function(state)
        vim.diagnostic.enable(state)
        require("tiny-inline-diagnostic").toggle()
    end,
  }):map '<leader>tD'
  Snacks.toggle.new({
    id = "[FF] RipGrep > Watchman",
    name = "[FF] RipGrep > Watchman",
    get = function() return vim.g.commandt_cmd_watchman end,
    set = function(state)
      vim.g.commandt_cmd_watchman = state
    end,
  }):map '<leader>tp'
  Snacks.toggle.new({
    id = "[GIT] Nav Hunks All Target",
    name = "[GIT] Nav Hunks All Target",
    get = function() return vim.g.gitsigns_nav_target == 'all' end,
    set = function(state)
      vim.g.gitsigns_nav_target = state and 'all' or 'unstaged'
    end,
  }):map '<leader>tc'
  Snacks.toggle.new({
    id = "[LSP] Words underline",
    name = "[LSP] Words underline",
    get = function() return Snacks.words.enabled end,
    set = function(state)
      if state then
        Snacks.words.enable()
      else
        Snacks.words.disable()
      end
    end,
  }):map '<leader>tu'
  Snacks.toggle.new({
    id = '[AI] Inline Completion',
    name = '[AI] Inline Completion',
    get = function() return vim.g.inline_completion_enabled or false end,
    set = function(state)
      vim.g.inline_completion_enabled = state
      vim.lsp.inline_completion.enable(state, { bufnr = vim.api.nvim_get_current_buf() })
    end,
  }):map '<leader>ti'
  Snacks.toggle.new({
    id = '[AI] Next Edit Suggestions',
    name = '[AI] Next Edit Suggestions',
    get = function() return not (vim.g.toggle_nes or false) end,
    set = function(state)
      vim.g.toggle_nes = state
      require("sidekick.nes").toggle()
    end,
  }):map '<leader>tn'
  Snacks.toggle.new({
    id = '[LSP] Auto Format',
    name = '[LSP] Auto Format',
    get = function() return vim.g.toggle_auto_format or false end,
    set = function(state)
      vim.g.toggle_auto_format = state
    end,
  }):map '<leader>tf'
  Snacks.toggle.new({
    id = '[GIT] Current Line Blame',
    name = '[GIT] Current Line Blame',
    get = function() return vim.g.toogle_blame_line or false end,
    set = function(state)
      vim.g.toogle_blame_line = state
      require 'gitsigns'.toggle_current_line_blame()
    end,
  }):map '<leader>tb'
  Snacks.toggle.new({
    id = '[GIT] Word Diff',
    name = '[GIT] Word Diff',
    get = function() return vim.g.toogle_word_diff or false end,
    set = function(state)
      vim.g.toogle_word_diff = state
      require 'gitsigns'.toggle_word_diff()
    end,
  }):map '<leader>td'
  Snacks.toggle.new({
    id = '[Spell] English Spelling',
    name = '[Spell] English Spelling',
    get = function() return vim.g.toogle_en_spell or false end,
    set = function(state)
      vim.g.toogle_en_spell = state
      vim.cmd 'setlocal spell! spelllang=en'
    end,
  }):map '<leader>tSe'
  Snacks.toggle.new({
    id = '[Spell] All Lang Spelling',
    name = '[Spell] All Lang Spelling',
    get = function() return vim.g.toogle_all_spell or false end,
    set = function(state)
      vim.g.toogle_all_spell = state
      vim.cmd 'setlocal spell! spelllang=en,fr'
    end,
  }):map '<leader>tSa'
  Snacks.toggle.new({
    id = '[Spell] French Spelling',
    name = '[Spell] French Spelling',
    get = function() return vim.g.toogle_fr_spell or false end,
    set = function(state)
      vim.g.toogle_fr_spell = state
      vim.cmd 'setlocal spell! spelllang=fr'
    end,
  }):map '<leader>tSf'
  Snacks.toggle.new({
    notify = false,
    id = '[LSP] Diagnostic Severity Cycle',
    name = '[LSP] Diagnostic Severity Cycle',
    get = function()
      return (vim.g.diagnostic_current_severity or vim.g.diagnostic_severities[1]) ~= vim.g.diagnostic_severities[1]
    end,
    set = function()
      local signs = vim.g.diagnostic_severities_signs

      vim.g.diagnostic_current_severity = vim.g.diagnostic_current_severity or vim.g.diagnostic_severities[1]
      local idx = 1
      for i, sev in ipairs(signs) do
        if sev.level == vim.g.diagnostic_current_severity then idx = i % #signs + 1 break end
      end
      vim.g.diagnostic_current_severity = signs[idx].level

      local new_severities = {}
      local filtered_signs = {}
      for _, symbol in ipairs(signs) do
        if symbol.level <= vim.g.diagnostic_current_severity then
          filtered_signs[symbol.level] = symbol.sign
          table.insert(new_severities, symbol.level)
        else
          filtered_signs[symbol.level] = ''
        end
      end
      vim.g.diagnostic_severities = new_severities
      vim.diagnostic.enable(false)
      require("tiny-inline-diagnostic").change_severities(new_severities)
      vim.diagnostic.config({
        signs = { text = filtered_signs },
      })
      vim.diagnostic.enable(true)
      vim.notify("Diagnostics: " .. signs[vim.g.diagnostic_current_severity].sign .. " " .. signs[vim.g.diagnostic_current_severity].text, vim.log.levels.INFO)
    end,
  }):map '<leader>te'
end

---@module 'lazy'
---@type LazySpec
return {
  'folke/snacks.nvim',
  priority = 2000,
  lazy = false,
  dependencies = {
    "folke/todo-comments.nvim",
    config = function()
      local todocomments = require 'todo-comments'
      todocomments.setup()

      vim.keymap.set('n', ']t', function()
        todocomments.jump_next()
      end, { desc = 'Next Todo Comment' })

      vim.keymap.set('n', '[t', function()
        todocomments.jump_prev()
      end, { desc = 'Previous Todo Comment' })
    end,
  },
  keys = {
    { '<leader>hB', function() Snacks.gitbrowse() end, desc = 'GIT: Open Browser' },
    { '<leader>hb', function() Snacks.git.blame_line() end, desc = 'GIT: Blame Line' },
    { '<leader>nd', function() Snacks.notifier.hide() end, desc = 'Notif Dismiss All' },
    { '<leader>np', function() Snacks.notifier.show_history() end, desc = 'Notif Preview' },

    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "LSP: Goto Definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "LSP: Goto Declaration" },
    { "gr", function() Snacks.picker.lsp_references({ include_declaration = false }) end, nowait = true, desc = "LSP: References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "LSP: Goto Implementation" },
    { "gt", function() Snacks.picker.lsp_type_definitions() end, desc = "LSP: Goto Type Definition" },
    { "<leader>gs", function() Snacks.picker.lsp_symbols() end, desc = "LSP: Symbols" },
    { "<leader>gS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP: Symbols in Project" },
    { "<leader>gi", function() Snacks.picker.lsp_incoming_calls() end, desc = "LSP: Calls Incoming" },
    { "<leader>go", function() Snacks.picker.lsp_outgoing_calls() end, desc = "LSP: Calls Outgoing" },
    { "<leader>gd", function() Snacks.picker.diagnostics_buffer() end, desc = "LSP: Diagnostics in Buffer" },
    { "<leader>gD", function() Snacks.picker.diagnostics() end, desc = "LSP: Diagnostics in Project" },

    { "<leader>hg", function() Snacks.picker.git_grep() end, desc = "GIT: Git Grep" },
    { "<leader>hl", function() Snacks.picker.git_log({layout = "my_big_ivylayout_vertical"}) end, desc = "GIT: Log" },
    { "<leader>hf", function() Snacks.picker.git_diff({layout = "my_big_ivylayout_vertical"}) end, desc = "GIT: Log" },

    { "ga", function() require("tiny-code-action").code_action({}) end, desc = "LSP: Code Actions" },
    { "]A", function() require("tiny-code-action").code_action({}) end, desc = "_LSP: Code Actions" },
    { "[A", function() require("tiny-code-action").code_action({}) end, desc = "_LSP: Code Actions" },
    { "gh", function() vim.lsp.buf.hover() end, desc = 'LSP: Hover', mode = { "v", "n" } },
    { "g=", function()
      local mode = vim.api.nvim_get_mode().mode
      if mode == 'n' then
        vim.lsp.buf.format { async = true, filter = function(client) return client.name == "null-ls" end }
      else
        vim.lsp.buf.format { async = true,  filter = function(client) return client.name == "null-ls" end }
      end
    end, desc = "LSP: format selection or buffer", mode = { "v", "n" } },
    -- See cmp.lua for integration with tabout
    -- { "<c-l>", function() vim.lsp.inline_completion.get() end,  expr = true, replace_keycodes = true, desc = "Accept inline completion", mode = {'i'} },
    { "<c-j>", function() vim.lsp.inline_completion.select({ count = 1 }) end,  expr = true, replace_keycodes = true, desc = "Accept inline completion", mode = {'i'} },
    { "<c-k>", function() vim.lsp.inline_completion.select({ count = -1 }) end,  expr = true, replace_keycodes = true, desc = "Accept inline completion", mode = {'i'} },

    { "<leader>u", function() Snacks.picker.undo() end, desc = "Undo tree" },


    { "]w", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Word Reference", mode = { "n", "t" } },
    { "[w", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },

    { "<leader>q", function() Snacks.picker.qflist() end, desc = "  Quickfix List Search" },

    { "<leader>to", function() Snacks.picker.todo_comments({ keywords = { "TODO", "HACK", "WARNING", "BUG", "NOTE", "INFO", "PERF", "ERROR" } }) end, desc = "Find Todo Comment Tags" },
  },
  config = function()
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
       hidden = { "preview" },
       reverse = true,
       layout = {
         box = 'vertical',
         backdrop = false,
         row = -1,
         width = 0,
         min_height = 14,
         height = 0.4,
         border = 'top',
         title = ' {title} {live} {flags}',
         title_pos = 'left',
         {
           box = 'horizontal',
           { win = 'list',    border = 'none' },
           { win = 'preview', title = '{preview}', width = 0.5, border = 'left' },
         },
         { win = 'input', height = 1, border = 'single' },
       },
     }
     layouts.my_ivylayout_vertical = {
       hidden = { "preview" },
       reverse = true,
       layout = {
         box = 'vertical',
         backdrop = false,
         row = -1,
         width = 0,
         min_height = 14,
         height = 0.4,
         border = 'top',
         title = ' {title} {live} {flags}',
         title_pos = 'left',
         {
       box = 'vertical',
       { win = 'preview', title = '{preview}', height = 0.7, border = 'bottom' },
       { win = 'list',    border = 'none' },
         },
         { win = 'input', height = 1, border = 'single' },
       },
     }
     layouts.my_big_ivylayout_vertical = {
       hidden = { },
       reverse = true,
       layout = {
         box = 'vertical',
         backdrop = false,
         row = -1,
         width = 0,
         min_height = 24,
         height = 0.95,
         border = 'top',
         title = ' {title} {live} {flags}',
         title_pos = 'left',
         {
       box = 'vertical',
       { win = 'preview', title = '{preview}', height = 0.8, border = 'bottom' },
       { win = 'list',    border = 'none' },
         },
         { win = 'input', height = 1, border = 'single' },
       },
     }

    require('snacks').setup {
      styles = {
        notification_history = {
          width = 0.8,
          height = 0.8,
        },
        notification = {
          ft = "markdown",
          zindex = 10,
          bo = { filetype = "snacks_notif" },
        },
      },
      rename = { enabled = true },
      toggle = { },
      bigfile = { enabled = true },
      words = { enabled = true, debounce = 100 },
      notifier = {
        enabled = true,
        timeout = 1000,
        margin = { right = 1, },
      },
      quickfile = { enabled = true },
      -- statuscolumn = { enabled = true, left = { "sign" }, },

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
        -- previewers = { git = { native = true }, }, -- doesn't allow to scroll in the layout
        sources = {
          files = { hidden = true },
          grep = { hidden = true },
          select = {
            kinds = {
              sidekick_cli = {
                layout = { preset = "my_ivylayout" },
              },
              sidekick_prompt = {
                layout = { preset = "my_ivylayout_vertical" },
              },
            },
            layout = {
              preset = "my_ivylayout",
            },
          },
        },
        prompt = "> ",
        layout = { preset = "my_ivylayout" },
        ui_select = true,
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
              ["<c-M-k>"] = { "preview_scroll_up", mode = { "i", "n" } },
              ["<c-M-j>"] = { "preview_scroll_down", mode = { "i", "n" } },
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
