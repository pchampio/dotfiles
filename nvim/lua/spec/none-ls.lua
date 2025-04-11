local M = {
  'nvimtools/none-ls.nvim',
  cond = not vim.g.diffmode,
  dependencies = {
    {
      'nvim-lua/plenary.nvim',
      'nvimtools/none-ls-extras.nvim',
    },
  },
  config = function()
    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
    local null_ls = require 'null-ls'

    null_ls.setup {
      sources = {
        null_ls.builtins.formatting.clang_format.with {
          disabled_filetypes = { 'java' }, -- use google_java_format formatter instead
        },
        null_ls.builtins.formatting.gofmt,
        null_ls.builtins.formatting.google_java_format,
        null_ls.builtins.formatting.prettierd.with {
          extra_args = { '--single-quote=true' },
        },
        null_ls.builtins.formatting.stylua,
        require 'none-ls.diagnostics.eslint_d',
        -- Python
        null_ls.builtins.diagnostics.pylint,
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.black.with {
          extra_args = { '--line-length=80', '--skip-string-normalization' },
        },
      },
      -- you can reuse a shared lspconfig on_attach callback here
      on_attach = function(client, bufnr)
        if client.supports_method 'textDocument/formatting' then
          vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
              -- on later neovim version, you should use vim.lsp.buf.format({ async = false }) instead
              vim.lsp.buf.format { async = false }
            end,
          })
        end
      end,
    }
  end,
}

return M
