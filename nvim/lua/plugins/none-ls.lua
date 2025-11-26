---@module 'lazy'
---@type LazySpec
return {
  'nvimtools/none-ls.nvim',
  cond = not vim.o.diff,
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
  },
  config = function()
    local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
    local null_ls = require 'null-ls'

    null_ls.setup {
      log_level = "warn",
      sources = {
        null_ls.builtins.formatting.clang_format.with {
          disabled_filetypes = { 'java' },
        },
        null_ls.builtins.formatting.gofmt,
        null_ls.builtins.formatting.google_java_format,
        null_ls.builtins.formatting.prettierd.with {
          extra_args = { '--single-quote=true' },
        },
        null_ls.builtins.formatting.stylua,
        -- Python
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.black.with {
          extra_args = { '--line-length=120', '--skip-string-normalization' },
        },
        -- shell
        null_ls.builtins.formatting.shfmt.with {
          extra_args = { '-i', '2', '-ci', '-bn' }, -- https://github.com/mvdan/sh/blob/ba0f5f2a1661a86e813dbe0ee0da60e46f12f56d/cmd/shfmt/shfmt.1.scd?plain=1#L125
          filetypes = { "bash", "zsh", "sh" },
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
              if (vim.g.toggle_auto_format or false) then
                vim.lsp.buf.format { async = false, timeout_ms = 1000,
                filter = function(client) return client.name == "null-ls" end,
                }
              end
            end,
          })
        end
      end,
    }
  end,
}
