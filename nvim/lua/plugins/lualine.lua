---@module 'lazy'
---@type LazySpec
return {
  event = "VeryLazy",
  'nvim-lualine/lualine.nvim',
  dependencies = {
    'nvim-mini/mini.icons',
    {'letieu/harpoon-lualine', dependencies = { { 'ThePrimeagen/harpoon', branch = 'harpoon2' } } },
  },
  config = function()
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
        'nvim-tree',
        'quickfix',
        'mundo',
        'avante',
        'symbols-outline',
        'trouble',
        {
          sections = {
            lualine_c = {
            {
              function()
                return ' '
              end,
              padding = { left = 1, right = 1 },
            }, {
              function()
                  local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
                  local adapter_url, path = require("oil.util").parse_url(buf_name)
                  assert(adapter_url ~= nil and path ~= nil, "invalid oil url")
                  local adapter_name = require("oil.config").adapters[adapter_url]
                  if adapter_name:upper() == "FILES" then
                    return vim.fn.fnamemodify(path, ":~")
                  end
                  return ("%s: %s"):format(adapter_name:upper(), vim.fn.fnamemodify(path, ":~"))
              end,
              },
              },
              lualine_d = {
              },
              lualine_x = {},
              lualine_y = {
                "oil_git_signs_diff",
              },
              lualine_z = {{
                color = { fg = '#655e49', bg = '#bfb8a3' },
                "branch",
                }
              },
          },
          filetypes = { "oil" },
        },
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
              modified = '  ',
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
              modified = '  ',
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
