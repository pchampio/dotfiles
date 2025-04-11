local M = {
  'hedyhli/outline.nvim',
  config = function()
    -- Example mapping to toggle outline
    vim.keymap.set(
      'n',
      '<leader>o',
      '<cmd>Outline<CR>',
      { desc = 'Toggle Outline' }
    )

    require('outline').setup {
      -- Your setup opts here (leave empty to use defaults)
      preview_window = {
        -- Automatically open preview of code location when navigating outline window
        auto_preview = true,
      },
    }
  end,
}

return M
