---@module 'lazy'
---@type LazySpec
local M = {
  'gbprod/yanky.nvim',
  event = 'CursorHold',
  keys = { { '<leader>P', function() Snacks.picker.yanky() end, mode = { 'n', 'x' }, desc = 'Open Yank History' } }, -- has to be there
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
    vim.keymap.set('n', '[y', '<Plug>(YankyCycleForward)', { desc = '󰳺  Yank' })
    vim.keymap.set('n', ']y', '<Plug>(YankyCycleBackward)', { desc = '󰳸  Yank' })
    vim.keymap.set('n', 'p', '<Plug>(YankyPutAfter)', { desc = 'Paste after' })
    vim.keymap.set('n', 'P', '<Plug>(YankyPutBefore)', { desc = 'Paste before' })
    vim.keymap.set('n', 'gp', '<Plug>(YankyPutIndentAfterLinewise)', { desc = '󰱖  paste Line Under' })
    vim.keymap.set('n', 'gP', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = '󰱘  Paste Line Above' })
  end,
}

return M
