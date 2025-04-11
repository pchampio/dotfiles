local M = {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'echasnovski/mini.icons' },
  config = function()
    local winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {
        {
          'filename',
          path = 1, -- 0: Just the filename
          -- 1: Relative path
          -- 2: Absolute path
          -- 3: Absolute path, with tilde as the home directory
          -- 4: Filename and parent dir, with tilde as the home directory
        },
      },
      lualine_y = {},
      lualine_z = {},
    }
    require('lualine').setup {
      options = {
        disabled_filetypes = { -- Filetypes to disable lualine for.
          winbar = { 'NvimTree', 'Outline', 'dap-repl', 'qf', 'trouble' }, -- only ignores the ft for winbar.
        },
      },
      extensions = {
        'lazy',
        'mason',
        'nvim-dap-ui',
        'nvim-tree',
        'quickfix',
        'symbols-outline',
        'trouble',
      },
      winbar = winbar,
      inactive_winbar = winbar,
    }
  end,
}

return M
