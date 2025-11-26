---@module 'lazy'
---@type LazySpec
return {
  {
    event = 'VeryLazy',
    'neovim/nvim-lspconfig',
    cond = not vim.o.diff,
    dependencies = {
      {
        { 'hrsh7th/cmp-nvim-lsp', opts = {} },
        'mason-org/mason.nvim',
      },
    },
    config = function()
      -- if vim.bo.filetype == 'bigfile' then
      --   return
      -- end

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

      vim.lsp.config('*', {
        root_dir = function (bufnr, cb)
          local root = vim.fs.root(bufnr, {'.git'}) or vim.fn.expand('%:p:h')
          cb(root)
        end,
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

      -- LSP formats / edits on type (like for auto f when typing '{' in python string)
      vim.lsp.on_type_formatting.enable()

      local filtered_severity_signs = {}
      for _, symbol in ipairs(vim.g.diagnostic_severities_signs) do
        if symbol.level <= vim.g.diagnostic_severities[1] then
          filtered_severity_signs[symbol.level] = symbol.sign
        else
          filtered_severity_signs[symbol.level] = ''
        end
      end
      vim.diagnostic.config {
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = {
          text = filtered_severity_signs,
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
  },
}
