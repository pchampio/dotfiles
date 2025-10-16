local root_markers = {
  '.git', 'install.sh',
  'pyproject.toml', 'requirements.txt', 'setup.py', 'Pipfile',
  'go.mod', 'go.work',
  'CMakeLists.txt', 'Makefile', 'configure', 'build.ninja',
}

local M = {
  'git@prr.re:Drakirus/command-t.git',
  build = 'cd lua/wincent/commandt/lib && make',
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
