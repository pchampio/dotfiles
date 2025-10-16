local M = {
  url = 'https://gitlab.com/schrieveslaach/sonarlint.nvim.git',
  cond = not vim.o.diff,
  dependencies = {
    'neovim/nvim-lspconfig',
    'mason-org/mason.nvim',
    'lewis6991/gitsigns.nvim',
  },
  config = function()
    require('sonarlint').setup {
      server = {
        cmd = {
          'sonarlint-language-server',
          -- Ensure that sonarlint-language-server uses stdio channel
          '-stdio',
          '-analyzers',
          -- paths to the analyzers you need, using those for python and java in this example
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarpython.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarcfamily.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjava.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonargo.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarhtml.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonariac.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjs.jar',
          vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjavasymbolicexecution.jar',
        },
      },
      filetypes = {
        'c',
        'go',
        'html',
        'css',
        'javascript',
        'typescript',
        'dockerfile',
        'python',
        'cpp',
        'java',
      },
    }
  end,
}

return M
