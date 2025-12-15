local root_markers = {
  '.git', 'install.sh',
  'pyproject.toml', 'requirements.txt', 'setup.py', 'Pipfile',
  'go.mod', 'go.work',
  'CMakeLists.txt', 'Makefile', 'configure', 'build.ninja',
}

---@module 'lazy'
---@type LazySpec
return {
  'git@prr.re:Drakirus/command-t.git',
  build = 'make',
  -- dir = "/home/prr/lab/git-commant-t",
  keys = {
    {
      '<C-p>',
      function()
        local cwd = vim.loop.cwd()
        local project_root =
            vim.fs.find(root_markers, { upward = true, path = cwd })[1]
        local watchman_exists = vim.loop.fs_stat(vim.fn.expand("~/.junest/bin/watchman")) ~= nil
        if vim.g.commandt_cmd_watchman and project_root and watchman_exists then
          require('wincent.commandt.finder')('watchman', '')
        else
          require('wincent.commandt.finder')('rg', '')
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
