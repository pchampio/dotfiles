local M = {
  'gbprod/yanky.nvim',
  event = 'CursorHold',
  config = function()
    vim.cmd [[hi YankyPut guifg=#37afd3 gui=underline,bold]]
    local mapping = require 'yanky.telescope.mapping'
    local mappings = mapping.get_defaults()
    mappings.i['<c-p>'] = nil
    mappings.i['<cr>'] =
      mapping.set_register(require('yanky.utils').get_default_register())
    require('yanky').setup {
      system_clipboard = { sync_with_ring = false },
      ring = { storage = 'memory' },
      picker = {
        telescope = {
          use_default_mappings = false,
          mappings = mappings,
        },
      },
      highlight = {
        on_put = true,
        on_yank = false,
        timer = 500,
      },
    }
    vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)')
    vim.keymap.set('n', '[y', '<Plug>(YankyCycleForward)')
    vim.keymap.set('n', ']y', '<Plug>(YankyCycleBackward)')
    vim.api.nvim_set_keymap(
      '',
      'p',
      '<Plug>(YankyPutAfter)',
      { desc = 'Paste after' }
    )
    vim.api.nvim_set_keymap(
      '',
      'P',
      '<Plug>(YankyPutBefore)',
      { desc = 'Paste before' }
    )
    vim.api.nvim_set_keymap(
      '',
      'gp',
      '<Plug>(YankyPutIndentAfterLinewise)',
      { desc = 'Paste G after' }
    )
    vim.api.nvim_set_keymap(
      '',
      'gP',
      '<Plug>(YankyPutIndentBeforeLinewise)',
      { desc = 'Paste G before' }
    )
    require('telescope').load_extension 'yank_history'
  end,
}

return M
