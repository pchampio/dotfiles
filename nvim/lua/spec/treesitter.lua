---@module 'lazy'
---@type LazySpec
local M = {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    { 'nvim-treesitter/nvim-treesitter-context', opts = { max_lines = 1 } },
    {
      'Wansmer/treesj',
      keys = {
        { 'gJ', '<cmd>TSJToggle<cr>', desc = '  Join Toggle' },
        { 'gS', '<cmd>TSJSplit<cr>', desc = '  Join Split' },
      },
      opts = { use_default_keymaps = false, max_join_length = 1000 },
    },
  },
  build = function()
    require('nvim-treesitter.install').update { with_sync = true } ()
  end,
  config = function()
    local configs = require 'nvim-treesitter.configs'
    configs.setup {
      -- A list of parser names, or 'all' (the five listed parsers should always be installed)
      ensure_installed = {
        'html',
        'css',
        'javascript',
        'tsx',
        'cmake',
        'make',
        'cpp',
        'bash',
        'python',
        'go',
        'java',
        'yaml',
        'sql',
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,

      -- Automatically install missing parsers when entering buffer
      -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
      auto_install = true,

      -- List of parsers to ignore installing (or 'all')
      ignore_install = {},
      modules = {},

      highlight = {
        enable = true,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        -- additional_vim_regex_highlighting = false,
      },
      textobjects = {
        lookahead = true,
        select = {
          enable = true,
          include_surrounding_whitespace = false,
          keymaps = {
            ['aa'] = { query = '@parameter.outer', desc = '󱘎  outer param' },
            ['ia'] = { query = '@parameter.inner', desc = '󱘎  inner param' },
            ['af'] = { query = '@function.outer', desc = '󱘎  all function' },
            ['if'] = { query = '@function.inner', desc = '󱘎  inner function' },
            ['am'] = { query = '@class.outer', desc = '󱘎  all class' },
            ['im'] = { query = '@class.inner', desc = '󱘎  inner class' },
            ['ac'] = { query = '@conditional.outer', desc = '󱘎  all conditional' },
            ['ic'] = { query = '@conditional.inner', desc = '󱘎  inner conditional' },
            ['aH'] = { query = '@assignment.lhs', desc = '󱘎  assignment lhs' },
            ['aL'] = { query = '@assignment.rhs', desc = '󱘎  assignment rhs' },
          },
        },
        swap = {
          enable = true,
          swap_next = { ['<A-.>'] = '@parameter.inner' },
          swap_previous = { ['<A-,>'] = '@parameter.inner' },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { [']m'] = '@function.outer', [']M'] = '@class.outer' },
          goto_previous_start = { ['[m'] = '@function.outer', ['[M'] = '@class.outer' },
        },
      },
      incremental_selection = {
        enable = false,
      },
      indent = {
        enable = true,
      },
    }

    vim.opt.foldenable = false -- Disable folding at startup.
  end,
}

return M
