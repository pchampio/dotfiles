---@module 'lazy'
---@type LazySpec
local M = {
  'git@prr.re:Drakirus/mini.clue',
  config = function()
    local miniclue = require 'mini.clue'
    miniclue.setup {
      -- Clue window settings
      window = {
        -- Floating window config
        config = { anchor = 'SE', row = 'auto', col = 'auto', width = 40, border = 'rounded' },
        -- Delay before showing clue window
        delay = 500,
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
        { mode = 'n', keys = 'zl', postkeys = '4z', desc = '  Pane right' },
        { mode = 'n', keys = 'zh', postkeys = '4z', desc = '  Pane left' },
        { mode = 'n', keys = '[y', postkeys = '[' },
        { mode = 'n', keys = ']y', postkeys = ']' },
        { mode = 'n', keys = ']c', postkeys = 'zt]' },
        { mode = 'n', keys = '[c', postkeys = 'zt[' },
        { mode = 'n', keys = '[d', postkeys = 'zt[' },
        { mode = 'n', keys = ']d', postkeys = 'zt]' },
        { mode = 'n', keys = '[w', postkeys = 'zt[' },
        { mode = 'n', keys = ']w', postkeys = 'zt]' },
        { mode = 'n', keys = '[t', postkeys = 'zt[' },
        { mode = 'n', keys = ']t', postkeys = 'zt]' },
      },
    }
  end,
}

return M
