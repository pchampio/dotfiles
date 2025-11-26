vim.api.nvim_set_var(
  'python3_host_prog',
  vim.fn.expand '~' .. '/.local/share/pytool/bin/python3'
)

local function bootstrap(author, name, opts)
  opts = opts or {}
  local path = vim.fn.stdpath 'data' .. '/' .. name .. '/' .. name .. '.nvim'
  if not vim.uv.fs_stat(path) then
    vim.api.nvim_echo({ { "Cloning " .. name .. "..", 'Info' } }, true, {})
    local repo = 'https://github.com/' .. author .. '/' .. name .. '.nvim'
    local cmd = { 'git', 'clone', '--branch=' .. (opts.branch or 'stable'), repo, path }
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({ { 'Failed to clone ' .. repo .. '.nvim:\n' .. out .. '\n' .. vim.inspect(cmd), 'Error' } }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.runtimepath:prepend(path)
end
bootstrap('jake-stewart', 'lazier', { branch = 'stable-v2' })

require('lazier').setup('plugins', {
  lazier = {
    enabled = true,
    detect_changes = true,
    before = function()
      -- function to run before the ui renders.
      -- it is faster to require parts of your config here
      -- since at this point they will be bundled and bytecode compiled.
      require 'options'
      require 'preautocmds'
    end,
    after = function()
      -- function to run after the ui renders.
      require 'postautocmds'
      require 'keymaps'
      require 'cmds'
      require 'spell'
    end,
    start_lazily = function()
      -- function which returns whether lazy.nvim
      -- should start delayed or not.
      local nonLazyLoadableExtensions = {
        zip = true,
        tar = true,
        gz = true,
      }
      local fname = vim.fn.expand '%'
      return fname == ''
        or vim.fn.isdirectory(fname) == 0
          and not nonLazyLoadableExtensions[vim.fn.fnamemodify(fname, ':e')]
    end,
  },
  -- lazy.nvim conf here
  git = {
    -- Configure lazyvim to use ssh instead of https
    url_format = 'git@github.com:%s.git',
  },
  spec = {
    -- Import your plugins
    { import = 'plugins' },
  },
  change_detection = {
      enabled = false,
      notify = false
  },
  performance = {
    cache = { enabled = true },
    reset_packpath = true,
    rtp = {
      reset = false,
      disabled_plugins = {
        "matchit",
        "matchparen",
        'tohtml',
        'tutor',
      },
    },
  },
})
