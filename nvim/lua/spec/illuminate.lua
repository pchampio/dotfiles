local M = {
  'RRethy/vim-illuminate',
  config = function()
    require('illuminate').configure {
      min_count_to_highlight = 2,
    }
  end,
}

return M
