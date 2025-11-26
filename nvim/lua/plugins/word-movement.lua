---@module 'lazy'
---@type LazySpec
return {
  'chrisgrieser/nvim-spider',
  opts = {
    subwordMovement = false,
  },
  keys = {
    {
      mode = { 'n', 'o', 'x' },
      'w',
      "<cmd>lua require('spider').motion('w')<cr>",
      desc = 'spider-w',
    },
    {
      mode = { 'n', 'o', 'x' },
      'e',
      "<cmd>lua require('spider').motion('e')<cr>",
      desc = 'spider-e',
    },
    {
      mode = { 'n', 'o', 'x' },
      'b',
      "<cmd>lua require('spider').motion('b')<cr>",
      desc = 'spider-b',
    },
  },
}
