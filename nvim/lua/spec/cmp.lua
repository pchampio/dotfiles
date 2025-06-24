local M = {
  'hrsh7th/nvim-cmp',
  -- name = 'nvim-cmp', -- Otherwise highlighting gets messed up (to use when testing a fork)
  dependencies = {
    --* the sources *--
    { 'hrsh7th/cmp-nvim-lsp', name = 'cmp-nvim-lsp', opts = {} },
    { 'hrsh7th/cmp-nvim-lua', name = 'cmp-nvim-lua' },
    { 'hrsh7th/cmp-buffer', name = 'cmp-buffer' },
    { 'hrsh7th/cmp-cmdline', name = 'cmp-cmdline' },

    'https://codeberg.org/FelipeLema/cmp-async-path', -- better than cmp-path

    { 'saadparwaiz1/cmp_luasnip' },
    { 'dmitmel/cmp-cmdline-history' },
    {
      -- https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#install
      'L3MON4D3/LuaSnip',
      -- follow latest release.
      version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = 'make install_jsregexp',
      dependencies = {
        'rafamadriz/friendly-snippets',
      },
    },
  },
  config = function()
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    local rhs = require('commons').utils.rhs

    -- https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#add-snippets
    require('luasnip.loaders.from_vscode').lazy_load()

    -- Returns the current column number.
    local column = function()
      local _line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col
    end

    -- Based on (private) function in LuaSnip/lua/luasnip/init.lua.
    local in_snippet = function()
      local session = require 'luasnip.session'
      local node = session.current_nodes[vim.api.nvim_get_current_buf()]
      if not node then
        return false
      end
      local snippet = node.parent.snippet
      local snip_begin_pos, snip_end_pos = snippet.mark:pos_begin_end()
      local pos = vim.api.nvim_win_get_cursor(0)
      if pos[1] - 1 >= snip_begin_pos[1] and pos[1] - 1 <= snip_end_pos[1] then
        return true
      end
    end

    -- Returns true if the cursor is in leftmost column or at a whitespace
    -- character.
    local in_whitespace = function()
      local col = column()
      return col == 0
        or vim.api.nvim_get_current_line():sub(col, col):match '%s'
    end

    local in_leading_indent = function()
      local col = column()
      local line = vim.api.nvim_get_current_line()
      local prefix = line:sub(1, col)
      return prefix:find '^%s*$'
    end

    local shift_width = function()
      if vim.o.softtabstop <= 0 then
        return vim.fn.shiftwidth()
      else
        return vim.o.softtabstop
      end
    end

    -- Complement to `smart_tab()`.
    --
    -- When 'noexpandtab' is set (ie. hard tabs are in use), backspace:
    --
    --    - On the left (ie. in the indent) will delete a tab.
    --    - On the right (when in trailing whitespace) will delete enough
    --      spaces to get back to the previous tabstop.
    --    - Everywhere else it will just delete the previous character.
    --
    -- For other buffers ('expandtab'), we let Neovim behave as standard and that
    -- yields intuitive behavior, unless the `dedent` parameter is truthy, in
    -- which case we issue <C-D> to dedent (see `:help i_CTRL-D`).
    local smart_bs = function(dedent)
      local keys = nil
      if vim.o.expandtab then
        if dedent then
          keys = rhs '<C-D>'
        else
          keys = rhs '<BS>'
        end
      else
        local col = column()
        local line = vim.api.nvim_get_current_line()
        local prefix = line:sub(1, col)
        if in_leading_indent() then
          keys = rhs '<BS>'
        else
          local previous_char = prefix:sub(#prefix, #prefix)
          if previous_char ~= ' ' then
            keys = rhs '<BS>'
          else
            -- Delete enough spaces to take us back to the previous tabstop.
            --
            -- Originally I was calculating the number of <BS> to send, but
            -- Neovim has some special casing that causes one <BS> to delete
            -- multiple characters even when 'expandtab' is off (eg. if you hit
            -- <BS> after pressing <CR> on a line with trailing whitespace and
            -- Neovim inserts whitespace to match.
            --
            -- So, turn 'expandtab' on temporarily and let Neovim figure out
            -- what a single <BS> should do.
            --
            -- See `:h i_CTRL-\_CTRL-O`.
            keys =
              rhs '<C-\\><C-o>:set expandtab<CR><BS><C-\\><C-o>:set noexpandtab<CR>'
          end
        end
      end
      vim.api.nvim_feedkeys(keys, 'nt', true)
    end

    -- In buffers where 'noexpandtab' is set (ie. hard tabs are in use), <Tab>:
    --
    --    - Inserts a tab on the left (for indentation).
    --    - Inserts spaces everywhere else (for alignment).
    --
    -- For other buffers (ie. where 'expandtab' applies), we use spaces everywhere.
    local smart_tab = function(opts)
      local keys = nil
      if vim.o.expandtab then
        keys = '<Tab>' -- Neovim will insert spaces.
      else
        local col = column()
        local line = vim.api.nvim_get_current_line()
        local prefix = line:sub(1, col)
        local in_leading_indent = prefix:find '^%s*$'
        if in_leading_indent then
          keys = '<Tab>' -- Neovim will insert a hard tab.
        else
          -- virtcol() returns last column occupied, so if cursor is on a
          -- tab it will report `actual column + tabstop` instead of `actual
          -- column`. So, get last column of previous character instead, and
          -- add 1 to it.
          local sw = shift_width()
          local previous_char = prefix:sub(#prefix, #prefix)
          local previous_column = #prefix - #previous_char + 1
          local current_column = vim.fn.virtcol {
            vim.fn.line '.',
            previous_column,
          } + 1
          local remainder = (current_column - 1) % sw
          local move = remainder == 0 and sw or sw - remainder
          keys = (' '):rep(move)
        end
      end

      vim.api.nvim_feedkeys(rhs(keys), 'nt', true)
    end

    local select_next_item = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end

    local select_prev_item = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end

    -- Until https://github.com/hrsh7th/nvim-cmp/issues/1716
    -- (cmp.ConfirmBehavior.MatchSuffix) gets implemented, use this local wrapper
    -- to choose between `cmp.ConfirmBehavior.Insert` and
    -- `cmp.ConfirmBehavior.Replace`:
    local confirm = function(entry)
      local behavior = cmp.ConfirmBehavior.Replace
      if entry then
        local completion_item = entry.completion_item
        local newText = ''
        if completion_item.textEdit then
          newText = completion_item.textEdit.newText
        elseif
          type(completion_item.insertText) == 'string'
          and completion_item.insertText ~= ''
        then
          newText = completion_item.insertText
        else
          newText = completion_item.word or completion_item.label or ''
        end

        -- How many characters will be different after the cursor position if we
        -- replace?
        local diff_after = math.max(0, entry.replace_range['end'].character + 1)
          - entry.context.cursor.col

        -- Does the text that will be replaced after the cursor match the suffix
        -- of the `newText` to be inserted? If not, we should `Insert` instead.
        if
          entry.context.cursor_after_line:sub(1, diff_after)
          ~= newText:sub(-diff_after)
        then
          behavior = cmp.ConfirmBehavior.Insert
        end
      end
      cmp.confirm { select = true, behavior = behavior }
    end

    -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#basic-customisations
    local kind_icons = {
      Text = '',
      Method = '󰆧',
      Function = '󰊕',
      Constructor = '',
      Field = '󰇽',
      Variable = '󰂡',
      Class = '󰠱',
      Interface = '',
      Module = '',
      Property = '󰜢',
      Unit = '',
      Value = '󰎠',
      Enum = '',
      Keyword = '󰌋',
      Snippet = '',
      Color = '󰏘',
      File = '󰈙',
      Reference = '',
      Folder = '󰉋',
      EnumMember = '',
      Constant = '󰏿',
      Struct = '',
      Event = '',
      Operator = '󰆕',
      TypeParameter = '󰅲',
    }

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body) -- For `luasnip` users.
        end,
      },

      completion = {
        completeopt = 'menu,menuone,noinsert',
      },

      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      preselect = cmp.PreselectMode.None,

      mapping = {
        ['<BS>'] = cmp.mapping(function(_fallback)
          smart_bs()
        end, { 'i', 's' }),

        ['<C-n>'] = cmp.mapping(function()
          if cmp.visible() then
            -- If there is only one completion candidate, use it.
            local entries = cmp.get_entries()
            if #entries == 1 then
              confirm(entries[1])
            else
              cmp.select_next_item()
            end
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          else
            cmp.complete()
          end
        end, { 'i', 's' }),

        ['<C-p>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif in_snippet() and luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),

        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-e>'] = cmp.mapping.scroll_docs(1),
        ['<C-y>'] = cmp.mapping.scroll_docs(-1),

        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if in_snippet() and luasnip.jumpable(-1) then
            luasnip.jump(-1)
          elseif in_leading_indent() then
            smart_bs(true) -- true means to dedent
          elseif in_whitespace() then
            smart_bs()
          else
            fallback()
          end
        end, { 'i', 's' }),

        ['<Tab>'] = cmp.mapping(function(_fallback)
          if cmp.visible() then
            local entry = cmp.get_selected_entry()
            confirm(entry)
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          elseif in_whitespace() then
            smart_tab()
          else
            cmp.complete()
          end
        end, { 'i', 's' }),
      },

      -- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#basic-customisations
      formatting = {
        format = function(entry, vim_item)
          -- Kind icons
          vim_item.kind =
            string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatenates the icons with the name of the item kind
          -- Source
          vim_item.menu = ({
            buffer = '[Buffer]',
            nvim_lsp = '[LSP]',
            luasnip = '[LuaSnip]',
            nvim_lua = '[Lua]',
            latex_symbols = '[LaTeX]',
          })[entry.source.name]
          return vim_item
        end,
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        -- { name = 'vsnip' }, -- For vsnip users.
        { name = 'luasnip' }, -- For luasnip users.
        -- { name = 'ultisnips' }, -- For ultisnips users.
        -- { name = 'snippy' }, -- For snippy users.
        { name = 'nvim_lua' }, -- https://github.com/hrsh7th/cmp-nvim-lua?tab=readme-ov-file#setup
        { name = 'lazydev', group_index = 0 }, -- set group index to 0 to skip loading LuaLS completions, https://github.com/folke/lazydev.nvim?tab=readme-ov-file#-installation
        { name = 'async_path' },
      }, {
        { name = 'buffer' },
      }),
      experimental = {
        ghost_text = true,
      },
    }

    -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline({ '/', '?' }, {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'buffer' },
      },
    })

    -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'cmdline_history' },
      }, {
        { name = 'async_path' },
      }, {
        { name = 'cmdline' },
      }),
      matching = { disallow_symbol_nonprefix_matching = false },
    })

    -- Only show ghost text at word boundaries, not inside keywords. Based on idea
    -- from: https://github.com/hrsh7th/nvim-cmp/issues/2035#issuecomment-2347186210

    local config = require 'cmp.config'

    local toggle_ghost_text = function()
      if vim.api.nvim_get_mode().mode ~= 'i' then
        return
      end

      local cursor_column = vim.fn.col '.'
      local current_line_contents = vim.fn.getline '.'
      local character_after_cursor =
        current_line_contents:sub(cursor_column, cursor_column)

      local should_enable_ghost_text = character_after_cursor == ''
        or vim.fn.match(character_after_cursor, [[\k]]) == -1

      local current = config.get().experimental.ghost_text
      if current ~= should_enable_ghost_text then
        config.set_global {
          experimental = {
            ghost_text = should_enable_ghost_text,
          },
        }
      end
    end

    vim.api.nvim_create_autocmd({ 'InsertEnter', 'CursorMovedI' }, {
      callback = toggle_ghost_text,
    })
  end,
}

return M
