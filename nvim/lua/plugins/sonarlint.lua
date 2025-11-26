return {
  event = 'VeryLazy',
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
        cmd = vim
          .iter({
            'sonarlint-language-server',
            '-stdio',
            '-analyzers',
            vim.fn.expand('$MASON/share/sonarlint-analyzers/*.jar', true, 1),
          })
          :flatten()
          :totable(),
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
