---@module 'lazy'
---@type LazySpec
local M = {
  event = { 'CursorHold' },
  'folke/sidekick.nvim',
  dependencies = {
    'folke/snacks.nvim',
  },
  config = function()
    require('sidekick').setup {
      nes = {
        trigger = {
          -- events that trigger sidekick next edit suggestions
          events = { 'TextChanged', 'User SidekickNesDone' },
        },
      },
      cli = {
        mux = {
          backend = 'tmux',
          enabled = true,
          create = 'split',
        },
      },
      tools = {
        opencode = {
          cmd = { 'opencode' },
        },
      },
    }
    local function set_sidekick_hl()
      vim.api.nvim_set_hl(0, 'testSidekickDiffContext', { link = 'Comment' })
      vim.api.nvim_set_hl(0, 'SidekickDiffAdd', { link = 'DiffAdd' })
      vim.api.nvim_set_hl(0, 'SidekickDiffDelete', { link = 'DiffDelete' })
      vim.api.nvim_set_hl(0, 'SidekickSign', { link = 'Comment' })
    end

    set_sidekick_hl()

    vim.api.nvim_create_autocmd('ColorScheme', {
      desc = 'Sidekick highlight adjustments',
      callback = set_sidekick_hl,
    })
  end,
  keys = {
    {
      '<leader><tab>',
      function()
        require('sidekick.nes').update()
      end,
      expr = true,
      desc = '󱚤  Request new edits from the LSP server',
    },
    {
      '<tab>',
      function()
        if require('sidekick').nes_jump_or_apply() then
          return
        end
        return '<tab>'
      end,
      expr = true,
      desc = '󱚤  Goto/Apply Next Edit Suggestion',
    },
    {
      '<leader>aa',
      function()
        require('sidekick.cli').toggle { name = 'opencode', focus = true }
      end,
      desc = '󱚤  Toggle CLI',
    },
    {
      '<leader>at',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      mode = { 'x', 'n' },
      desc = '󱚤  Send This',
    },
    {
      '<leader>av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      mode = { 'x' },
      desc = '󱚤  Send Visual Selection',
    },
    {
      '<leader>ap',
      function()
        require('sidekick.cli').prompt { layout = { preset = 'my_ivylayout' } }
      end,
      mode = { 'n', 'x' },
      desc = '󱚤  Prompt (visual/normal context)',
    },
  },
}

return M
