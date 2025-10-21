---@module 'lazy'
---@type LazySpec
local M = {
  'gbprod/yanky.nvim',
  event = 'CursorHold',
  config = function()
    vim.cmd [[hi YankyPut guifg=#37afd3 gui=underline,bold]]
    require('yanky').setup {
      system_clipboard = { sync_with_ring = false },
      ring = { storage = 'memory' },
      picker = {},
      highlight = {
        on_put = true,
        on_yank = false,
        timer = 500,
      },
    }
    vim.keymap.set({ 'n', 'x' }, 'y', '<Plug>(YankyYank)')
    vim.keymap.set('n', '[y', '<Plug>(YankyCycleForward)')
    vim.keymap.set('n', ']y', '<Plug>(YankyCycleBackward)')
    vim.api.nvim_set_keymap('', 'p', '<Plug>(YankyPutAfter)', { desc = 'Paste after' })
    vim.api.nvim_set_keymap('', 'P', '<Plug>(YankyPutBefore)', { desc = 'Paste before' })
    vim.api.nvim_set_keymap('', 'gp', '<Plug>(YankyPutIndentAfterLinewise)', { desc = 'Paste G after' })
    vim.api.nvim_set_keymap('', 'gP', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = 'Paste G before' })
  end,
}

return M
