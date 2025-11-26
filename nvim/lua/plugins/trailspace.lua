---@module 'lazy'
---@type LazySpec
return {
  'nvim-mini/mini.trailspace',
  keys = {
    {
      '<leader>ts',
      function()
        require('mini.trailspace').trim()
      end,
      desc = 'Trim White Space',
    },
  },
}
