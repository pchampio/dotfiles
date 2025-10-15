local enhance_scorec_link = "'https://gist.githubusercontent.com/pchampio/dc0e5392cb534b6e33ac3c5a152d52e2/raw/commandt_score.c'"

local root_markers = {
  '.git', 'install.sh',
  'pyproject.toml', 'requirements.txt', 'setup.py', 'Pipfile',
  'go.mod', 'go.work',
  'CMakeLists.txt', 'Makefile', 'configure', 'build.ninja',
}

local M = {
  'wincent/command-t',
  build = 'cd lua/wincent/commandt/lib && curl -sS ' .. enhance_scorec_link .. ' -o score.c  && make',

  keys = {
    {
      '<C-p>',
      function()
        local cwd = vim.loop.cwd()
        local project_root =
            vim.fs.find(root_markers, { upward = true, path = cwd })[1]
        if project_root then
          vim.cmd 'CommandTWatchman'
        else
          vim.cmd 'CommandTRipgrep'
        end
      end,
    },
  },
  config = function()
    require('wincent.commandt').setup {
      height = 6,
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
          ['<CR>'] = 'open',
          ['<C-c>'] = '<C-c>',
          ['<C-a>'] = '<C-c>bi',
          ['<Space>'] = '<C-c>bi<Space><Left>',
          ['<C-e>'] = '<End>',
        },
      },
      traverse = 'file',
      root_markers = root_markers,
      match_listing = {
        border = { '─', '─', '─', ' ', '┐', '─', '┌', ' ' },
      },
    }
  end,
}
return M
