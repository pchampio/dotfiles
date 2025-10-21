---@module 'lazy'
---@type LazySpec
local M = {
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-mini/mini.icons',
    {
      'letieu/harpoon-lualine',
      dependencies = {
        {
          'ThePrimeagen/harpoon',
          branch = 'harpoon2',
        },
      },
    },
  },
  init = function()
    local config = {
      options = {
        disabled_filetypes = { -- Filetypes to disable lualine for.
          statusline = { 'NvimTree', 'Outline', 'dap-repl', 'qf', 'trouble' }, -- only ignores the ft for winbar.
        },
        globalstatus = false,
      },
      extensions = {
        'lazy',
        'mason',
        'nvim-dap-ui',
        'oil',
        'nvim-tree',
        'quickfix',
        'mundo',
        'avante',
        'symbols-outline',
        'trouble',
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {
          {
            'filename',
            separator = { right = '' },
            symbols = {
              modified = ' ',
            },
          },
        },
      },
      sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            function()
              return ' '
            end,
            padding = { left = 1, right = 1 },
          },
          {
            'filename',
            separator = { right = '' },
            symbols = {
              modified = ' ',
            },
          },
          { '%=', separator = { left = '' } },
          {
            'harpoon2',
            icon = '',
            indicators = { 'y', 'u', 'i', 'o' },
            active_indicators = { '[Y]', '[U]', '[I]', '[O]' },
            color_active = { gui = 'bold', fg = '#23333c' },
          },
        },
        lualine_x = { 'diff', 'diagnostics' },
        lualine_y = {
          'filetype',
        },
        lualine_z = {
          {
            color = { fg = '#655e49', bg = '#bfb8a3' },
            function()
              local line = vim.fn.line '.'
              local col = vim.fn.col '.'
              local total_line = vim.fn.line '$'

              -- Get the number of digits in total_line and current col
              local line_width = math.max(#tostring(total_line), 2) -- at least 2 for aesthetics
              local col_width = math.max(#tostring(col), 2)

              -- Pad line and col with spaces on the left to match max width
              local line_str = string.rep(' ', line_width - #tostring(line))
                .. line
              local total_line_str = string.rep(
                ' ',
                line_width - #tostring(total_line)
              ) .. total_line
              local col_str = string.rep(' ', col_width - #tostring(col)) .. col

              return string.format(
                'ℓ:%s/%s 𝚌:%s',
                line_str,
                total_line_str,
                col_str
              )
            end,
          },
        },
      },
    }

    require('lualine').setup(config)
  end,
}

return M
