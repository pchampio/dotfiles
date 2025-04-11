local M = {
  'folke/todo-comments.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local todocomments = require 'todo-comments'
    todocomments.setup()

    vim.keymap.set('n', ']t', function()
      todocomments.jump_next()
    end, { desc = 'Next todo comment' })

    vim.keymap.set('n', '[t', function()
      todocomments.jump_prev()
    end, { desc = 'Previous todo comment' })
  end,
}

return M
