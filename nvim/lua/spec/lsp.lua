local M = {
  'neovim/nvim-lspconfig',
  cond = not vim.g.diffmode, -- 'cond' would install but not load the plugin, whereas 'enabled' would not install the plugin at all
  dependencies = {
    {
      { 'iguanacucumber/mag-nvim-lsp', name = 'cmp-nvim-lsp', opts = {} },
    },
  },
  config = function()
    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        vim.keymap.set('n', '<leader>fl', function()
          vim.lsp.buf.format { async = true }
        end, { buffer = args.buf, desc = 'LSP: format buffer' })

        vim.keymap.set('n', '<leader>H', function()
          if not vim.lsp.inlay_hint.is_enabled() then
            print 'Inlay hint enabled'
          else
            print 'Inlay hint disable'
          end
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, { desc = 'LSP: toggle inlay hint' })
      end,
    })

    ----------

    -- https://github.com/hrsh7th/cmp-nvim-lsp?tab=readme-ov-file#setup
    -- The nvim-cmp almost supports LSP's capabilities so You should advertise it to LSP servers..
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    for _, server in pairs(require('commons').servers) do
      local opts = {
        capabilities = capabilities,
      }

      local require_ok, settings = pcall(require, 'settings.' .. server)
      if require_ok then
        opts = vim.tbl_deep_extend('force', settings, opts)
      end

      require('lspconfig')[server].setup(opts)
    end

    -- https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization#change-diagnostic-symbols-in-the-sign-column-gutter
    local signs =
    { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
    for type, icon in pairs(signs) do
      local hl = 'DiagnosticSign' .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

    vim.diagnostic.config {
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = 'rounded',
        source = true,
      },
      virtual_text = false, -- tiny-inline-diagnostic needs this set to false
      -- virtual_lines = {
      --   current_line = true,
      -- },
    }
  end,
}

return M
