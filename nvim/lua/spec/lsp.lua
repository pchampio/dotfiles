---@module 'lazy'
---@type LazySpec
local M = {
  'neovim/nvim-lspconfig',
  cond = not vim.o.diff, -- 'cond' would install but not load the plugin, whereas 'enabled' would not install the plugin at all
  dependencies = {
    {
      { 'hrsh7th/cmp-nvim-lsp', opts = {} },
      'mason-org/mason.nvim',
    },
  },
  config = function()
    -- LSP formats / edits on type (like for auto f when typing '{' in python string)
    vim.lsp.on_type_formatting.enable()
    -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
    local default_caps = vim.lsp.protocol.make_client_capabilities()
    local cmp_caps = require('cmp_nvim_lsp').default_capabilities()
    local capabilities = vim.tbl_deep_extend('force', default_caps, cmp_caps)


    --- Setup capabilities to support utf-16, since copilot.lua only works with utf-16
    --- this is a workaround to the limitations of copilot language server
    capabilities = vim.tbl_deep_extend('force', capabilities, {
      offsetEncoding = { 'utf-16' },
      general = {
        positionEncodings = { 'utf-16' },
      },
    })

    for _, server in pairs(require('commons').servers) do
      local opts = {
        capabilities = capabilities,
      }

      local require_ok, settings = pcall(require, 'settings.' .. server)
      if require_ok then
        opts = vim.tbl_deep_extend('force', settings, opts)
      end

      vim.lsp.config(server, opts)
      vim.lsp.enable(server)
    end

    vim.diagnostic.config {
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = '✘',
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = '⚑',
          [vim.diagnostic.severity.INFO] = "◉",
        },
      },
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
      virtual_text = false, -- tiny-inline-diagnostic needs this set to false
    }
  end,
}

return M
