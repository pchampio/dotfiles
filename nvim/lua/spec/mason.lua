---@module 'lazy'
---@type LazySpec
local M = {
  {
    'mason-org/mason.nvim',
    ---@module 'mason'
    ---@type MasonSettings
    opts = {
      ui = {
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    },
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = {
      'mason-org/mason.nvim',
      {
        'mason-org/mason-lspconfig.nvim',
        dependencies = {
          'neovim/nvim-lspconfig',
        },
        ---@module 'mason-lspconfig'
        opts = {
          automatic_enable = false, -- enable manually via `vim.lsp.enable()`
        },
      },
    },
    config = function()
      local ensure_installed = vim.list_extend({
        'sonarlint-language-server',
        'isort',
        'black',
        'shellcheck', -- https://github.com/bash-lsp/bash-language-server?tab=readme-ov-file#dependencies
        'shfmt', -- https://github.com/bash-lsp/bash-language-server?tab=readme-ov-file#dependencies
      }, require('commons').servers)
      if vim.g.go then
        ensure_installed =
          vim.list_extend({ 'delve', 'gofumpt' }, ensure_installed)
      end

      require('mason-tool-installer').setup {
        ensure_installed = ensure_installed,
      }
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsStartingInstall',
        callback = function()
          vim.schedule(function()
            print 'mason-tool-installer is starting'
          end)
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MasonToolsUpdateCompleted',
        callback = function(e)
          vim.schedule(function()
            if next(e.data) ~= nil then
              print(
                'mason-tool-installer installed/updated ' .. vim.inspect(e.data)
              ) -- print the table that lists the programs that were installed
            end
          end)
        end,
      })
    end,
  },
}

return M
