local M = {
  'ThePrimeagen/harpoon',
  lazy = true,
  keys = {
    {
      '<leader>h<space>',
      function()
        require('harpoon.ui').toggle_quick_menu()
      end,
      desc = '󱕘 Edit marks',
    },
    {
      '<leader>hp',
      '<cmd>Telescope harpoon marks<cr>',
      desc = '󱕘 Show marks',
    },
    {
      '<leader>hh',
      function()
        require('harpoon.mark').add_file()
      end,
      desc = '󱕘 Mark this file',
    },
    {
      '<A-y>',
      function()
        require('harpoon.ui').nav_file(1)
      end,
      desc = '󱕘 Navigate to file 1',
    },
    {
      '<A-u>',
      function()
        require('harpoon.ui').nav_file(2)
      end,
      desc = '󱕘 Navigate to file 2',
    },
    {
      '<A-i>',
      function()
        require('harpoon.ui').nav_file(3)
      end,
      desc = '󱕘 Navigate to file 3',
    },
    {
      '<A-o>',
      function()
        require('harpoon.ui').nav_file(4)
      end,
      desc = '󱕘 Navigate to file 4',
    },
    {
      '<A-p>',
      function()
        require('harpoon.ui').nav_file(5)
      end,
      desc = '󱕘 Navigate to file 4',
    },
  },
  config = function()
    require('telescope').load_extension 'harpoon'
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
}
return M
