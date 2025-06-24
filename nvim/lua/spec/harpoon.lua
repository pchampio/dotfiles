local M = {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  lazy = true,
  opts = {},
  keys = {
    {
      '<leader>h<space>',
      function()
        local harpoon = require 'harpoon'
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = '󱕘 Edit marks',
    },
    {
      '<leader>hh',
      function()
        local harpoon = require 'harpoon'
        harpoon:list():add()
      end,
      desc = '󱕘 Mark this file',
    },
    {
      '<A-y>',
      function()
        require('harpoon'):list():select(1)
      end,
      desc = '󱕘 Navigate to file 1',
    },
    {
      '<A-u>',
      function()
        require('harpoon'):list():select(2)
      end,
      desc = '󱕘 Navigate to file 2',
    },
    {
      '<A-i>',
      function()
        require('harpoon'):list():select(3)
      end,
      desc = '󱕘 Navigate to file 3',
    },
    {
      '<A-o>',
      function()
        require('harpoon'):list():select(4)
      end,
      desc = '󱕘 Navigate to file 4',
    },
  },
}
return M
