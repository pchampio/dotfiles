local M = {
  'nvim-mini/mini.trailspace',
  keys = {
    {
      '<leader>ts',
      function()
        require('mini.trailspace').trim()
      end,
      desc = '󱁐  Trim white space',
    },
  },
}
return M
