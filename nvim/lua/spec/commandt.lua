local enhance_scorec_link = "'https://gist.githubusercontent.com/pchampio/dc0e5392cb534b6e33ac3c5a152d52e2/raw/82656944fb3144d187bc6306a2e7dacc2e5f6d44/commandt_score.c'"
local M = {
  'wincent/command-t',
  build = 'cd lua/wincent/commandt/lib && curl -sS ' .. enhance_scorec_link .. ' -o score.c  && make',

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
