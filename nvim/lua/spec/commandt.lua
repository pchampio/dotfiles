local M = {
  'wincent/command-t',
  dependencies = {
    { 'https://git.prr.re/Drakirus/cpsm', build = 'PY3=ON bash install.sh' },
  },
  build = 'cd lua/wincent/commandt/lib && make',
  keys = {
    {
      '<C-p>',
      '<Plug>(CommandTRipgrep)',
    },
  },
  config = function()
    require('wincent.commandt').setup {
      height = 5, -- relative height (like 40%)
      position = 'bottom', -- ivy-style (bottom input)
      margin = 0,
      -- Keymaps adapted from snacks config
      mappings = {
        i = {
          ['<Esc>'] = 'close',
          ['<C-j>'] = 'select_next',
          ['<C-k>'] = 'select_previous',
          ['<Tab>'] = 'open_split',
          ['<C-s>'] = 'open_vsplit',
          ['<C-p>'] = 'toggle_preview',
          ['<CR>'] = 'open',
          ['<C-c>'] = '<C-c>',
        },
      },
      traverse = 'file',
      root_markers = {
        '.git',
        'install.sh',
        -- Python
        'pyproject.toml', -- modern Python projects (poetry, pdm)
        'requirements.txt', -- classic Python projects
        'setup.py', -- Python package
        'Pipfile', -- pipenv

        -- Go
        'go.mod', -- Go modules
        'go.work', -- Go workspace

        -- C / C++
        'CMakeLists.txt', -- CMake projects
        'Makefile', -- classic build systems
        'configure', -- autotools
        'build.ninja', -- Ninja build
      },
    }
  end,
}
return M
