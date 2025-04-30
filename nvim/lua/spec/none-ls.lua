local M = {
  'nvimtools/none-ls.nvim',
  cond = not vim.g.diffmode,
  dependencies = {
    {
      'nvim-lua/plenary.nvim',
    },
  },
  config = function()
    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
    local null_ls = require 'null-ls'
    local auto_format_enabled = true -- Variable to track the state of auto-formatting

    -- Function to toggle auto-formatting
    function Toggle_auto_format()
      auto_format_enabled = not auto_format_enabled
      if auto_format_enabled then
        print 'Auto-formatting enabled'
      else
        print 'Auto-formatting disabled'
      end
    end

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
        -- Python
        null_ls.builtins.diagnostics.pylint,
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.black.with {
          extra_args = { '--line-length=80', '--skip-string-normalization' },
        },
      },
      -- you can reuse a shared lspconfig on_attach callback here
      on_attach = function(client, bufnr)
        if client:supports_method 'textDocument/formatting' then
          vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
          vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
              if auto_format_enabled then
                vim.lsp.buf.format { async = false, timeout_ms = 1000 }
              end
            end,
          })
        end
      end,
    }
    -- Bind the toggle function to a key combination, e.g., <leader>tf
    vim.api.nvim_set_keymap(
      'n',
      '<leader>tf',
      ':lua Toggle_auto_format()<CR>',
      { noremap = true, silent = true, desc = 'Toggle auto format' }
    )
  end,
}

return M
