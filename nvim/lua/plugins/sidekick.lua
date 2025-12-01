---@module 'lazy'
---@type LazySpec
return {
  event = { 'CursorHold' },
  'folke/sidekick.nvim',
  dependencies = {
    'folke/snacks.nvim',
  },
  init = function()
    require('sidekick').setup {
      nes = {
        trigger = {
          -- events that trigger sidekick next edit suggestions
          events = { 'TextChanged', 'User SidekickNesDone' },
        },
        clear = {
          events = { "TextChangedI", "InsertEnter" },
          esc = false, -- use <leader><space> to clear instead (like for Loupe)
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
    local new_bg = vim.api.nvim_get_hl(0, { name = "FoldColumn" }).bg
    local diffadd = vim.api.nvim_get_hl(0, { name = "DiffAdd" })
    local diffdelete = vim.api.nvim_get_hl(0, { name = "DiffDelete" })
    diffadd.bg = new_bg
    diffdelete.bg = new_bg
    local function set_sidekick_hl()
      vim.api.nvim_set_hl(0, 'SidekickDiffContext', { link = 'NONE' })
      vim.api.nvim_set_hl(0, 'SidekickDiffAdd', diffadd)
      vim.api.nvim_set_hl(0, 'SidekickDiffDelete', diffdelete)
      vim.api.nvim_set_hl(0, 'SidekickSign', { link = 'Comment' })
    end

    set_sidekick_hl()

    vim.api.nvim_create_autocmd('InsertEnter', {
      desc = 'Sidekick highlight adjustments',
      callback = set_sidekick_hl,
    })

    -- Automatically disable diagnostics when the sidekick NES is shown
    local disabled = false
    local was_enable_hint = false
    vim.api.nvim_create_autocmd('User', {
      pattern = 'SidekickNesHide',
      callback = function()
        if disabled then
          disabled = false
          require('tiny-inline-diagnostic').enable()
          if was_enable_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = 0 })
          end
        end
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      pattern = 'SidekickNesShow',
      callback = function()
        disabled = true
        require('tiny-inline-diagnostic').disable()
        was_enable_hint = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
        if was_enable_hint then
          vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
        end
      end,
    })

  end,
  keys = {
    { '<leader><tab>', function() require('sidekick.nes').update() end, expr = true, desc = '  Request new edits from the LSP server' },
    { '<tab>', function() if require('sidekick').nes_jump_or_apply() then return end return '<tab>' end, expr = true, desc = '  Goto/Apply Next Edit Suggestion' },
    { '<leader>aa', function() require('sidekick.cli').toggle { name = 'opencode', focus = true } end, desc = '  Toggle CLI' },
    { '<leader>at', function() require('sidekick.cli').send { msg = '{this}' } end, mode = { 'x', 'n' }, desc = '  Send This' },
    { '<leader>av', function() require('sidekick.cli').send { msg = '{selection}' } end, mode = { 'x' }, desc = '  Send Visual Selection' },
    { '<leader>ap', function() require('sidekick.cli').prompt { layout = { preset = 'my_ivylayout' } } end, mode = { 'n', 'x' }, desc = '  Prompt CLI' },
  },
}
