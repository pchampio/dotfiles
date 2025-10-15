vim.loader.enable()
vim.api.nvim_set_var(
  'python3_host_prog',
  vim.fn.expand '~' .. '/.local/share/pytool/bin/python3'
)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ','
vim.g.maplocalleader = ','

require 'options'
require 'keymaps'
require 'plugins'
require 'autocmds'
require 'cmds'
require 'spell'
