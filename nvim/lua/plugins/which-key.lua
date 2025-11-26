---@module 'lazy'
---@type LazySpec
return {
  'git@prr.re:Drakirus/mini.clue.git',
  priority = 1001,
  lazy = false,
  config = function()
    local miniclue = require 'mini.clue'
    miniclue.setup {
      -- Clue window settings
      window = {
        -- Floating window config
        config = { anchor = 'SE', row = 'auto', col = 'auto', width = 40, border = 'rounded' },
        -- Delay before showing clue window
        delay = 100,
        -- Keys to scroll inside the clue window
        scroll_down = '<C-e>',
        scroll_up = '<C-y>',
      },
      triggers = {
        -- sandwich
        { mode = 'n', keys = 'd' },
        { mode = 'n', keys = 'c' },
        { mode = 'n', keys = 'S' },
        { mode = 'x', keys = 'd' },
        { mode = 'x', keys = 'c' },
        { mode = 'x', keys = 'S' },
        { mode = 'x', keys = 'i' },
        { mode = 'x', keys = 'a' },
        { mode = 'o', keys = 'i' },
        { mode = 'o', keys = 'a' },
        -- Leader triggers
        { mode = 'n', keys = '<Leader>' },
        { mode = 'x', keys = '<Leader>' },
        -- `g` key
        { mode = 'n', keys = 'g' },
        { mode = 'x', keys = 'g' },
        -- Marks
        { mode = 'n', keys = "'" },
        { mode = 'n', keys = '`' },
        { mode = 'x', keys = "'" },
        { mode = 'x', keys = '`' },
        -- Registers
        { mode = 'n', keys = '"' },
        { mode = 'x', keys = '"' },
        { mode = 'i', keys = '<C-r>' },
        { mode = 'c', keys = '<C-r>' },
        -- Window commands
        { mode = 'n', keys = '<C-w>' },
        -- `z` key
        { mode = 'n', keys = 'z' },
        { mode = 'x', keys = 'z' },
        -- `][` keys
        { mode = 'n', keys = ']' },
        { mode = 'n', keys = '[' },
      },
      clues = { -- hydra like
        { mode = 'n', keys = 'g*',     desc = '* without <>' },
        { mode = 'n', keys = '<leader>t',     desc = '[Toggle]' },
        { mode = 'n', keys = '<leader>s',     desc = '[Spell]' },
        { mode = 'n', keys = '<leader>n',     desc = '[Notif]' },
        { mode = 'n', keys = '<leader>a',     desc = '[AI]' },
        { mode = 'n', keys = '<leader>g',     desc = '[LSP]' },
        { mode = 'n', keys = '<leader>h',     desc = '[Harpoon/Git]' },
        { mode = 'n', keys = '<leader>c',     desc = '[Comment]' },
        { mode = 'n', keys = 'g?',     desc = '[DebugPrint]' },
        { mode = 'n', keys = '<leader>tS',     desc = '[Spell]' },
        { mode = 'n', keys = 'gR',     desc = 'Enter Virtual Replace mode' },
        { mode = 'n', keys = 'g&',     desc = 'Repeat last `:s` on all lines' },
        -- miniclue.gen_clues.marks(),
        miniclue.gen_clues.registers(),
        -- miniclue.gen_clues.windows(),
        -- miniclue.gen_clues.z(),
        { mode = 'n', keys = 'zl', postkeys = '4z', desc = '  Pane Right' },
        { mode = 'n', keys = 'zh', postkeys = '4z', desc = '  Pane Left' },
        { mode = 'n', keys = 'zL', postkeys = 'z', desc = '  Pane Right More' },
        { mode = 'n', keys = 'zH', postkeys = 'z', desc = '  Pane Left More' },
        { mode = 'n', keys = '[y', postkeys = '[', postkeys_next_allowed = { 'y', 'Y' } },
        { mode = 'n', keys = ']y', postkeys = ']', postkeys_next_allowed = { 'y', 'Y' } },
        { mode = 'n', keys = '[Y', postkeys = '[', postkeys_next_allowed = { 'y', 'Y' } },
        { mode = 'n', keys = ']Y', postkeys = ']', postkeys_next_allowed = { 'y', 'Y' } },
        -- Gitsigns
        { mode = 'n', keys = ']c', postkeys = ']', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- next hunk
        { mode = 'n', keys = '[c', postkeys = '[', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- prev hunk
        { mode = 'n', keys = ']C', postkeys = ']', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- prev hunk (same [ ] but reverse because capital letter)
        { mode = 'n', keys = '[C', postkeys = '[', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- next hunk (same [ ] but reverse because capital letter)
        { mode = 'n', keys = ']r', postkeys = ']', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- hunk undo/reset
        { mode = 'n', keys = '[r', postkeys = '[', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- hunk undo/reset
        { mode = 'n', keys = ']u', postkeys = ']', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- hunk undo/reset
        { mode = 'n', keys = '[u', postkeys = '[', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- hunk undo/reset
        { mode = 'n', keys = ']a', postkeys = ']', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- hunk stage/add
        { mode = 'n', keys = '[a', postkeys = ']', postkeys_next_allowed = { 'c', 'C', 'a', 'r', 'u' } }, -- hunk stage/add

        { mode = 'n', keys = '[D', postkeys = '[', postkeys_next_allowed = { 'd', 'D', 'A' } },
        { mode = 'n', keys = ']D', postkeys = ']', postkeys_next_allowed = { 'd', 'D', 'A' } },
        { mode = 'n', keys = '[d', postkeys = '[', postkeys_next_allowed = { 'd', 'D', 'A' } },
        { mode = 'n', keys = ']d', postkeys = ']', postkeys_next_allowed = { 'd', 'D', 'A' } },
        { mode = 'n', keys = '[w', postkeys = '[', postkeys_next_allowed = { 'w' } },
        { mode = 'n', keys = ']w', postkeys = ']', postkeys_next_allowed = { 'w' } },
        { mode = 'n', keys = '[t', postkeys = '[', postkeys_next_allowed = { 't' } },
        { mode = 'n', keys = ']t', postkeys = ']', postkeys_next_allowed = { 't' } },

        { mode = 'n', keys = ']m', postkeys = ']', postkeys_next_allowed = { 'm', 'M' } }, -- Tree-sitter-move
        { mode = 'n', keys = '[m', postkeys = '[', postkeys_next_allowed = { 'm', 'M' } },
        { mode = 'n', keys = ']M', postkeys = ']', postkeys_next_allowed = { 'm', 'M' } },
        { mode = 'n', keys = '[M', postkeys = '[', postkeys_next_allowed = { 'm', 'M' } },
        { mode = 'n', keys = ']f', postkeys = ']', postkeys_next_allowed = { 'f', 'F' } },
        { mode = 'n', keys = '[f', postkeys = '[', postkeys_next_allowed = { 'f', 'F' } },
        { mode = 'n', keys = ']F', postkeys = ']', postkeys_next_allowed = { 'f', 'F' } },
        { mode = 'n', keys = '[F', postkeys = '[', postkeys_next_allowed = { 'f', 'F' } },


        { mode = 'n', keys = '<leader>d', postkeys = '<leader>', postkeys_next_allowed = { 'd' } },
        { mode = 'n', keys = '<leader>hp', postkeys = '<leader>h', postkeys_next_allowed = { 'p' }, resolve_callback = require('commons').smart_hide_floating_window },
      },
    }
  end,
}
