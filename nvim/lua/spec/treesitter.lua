local M = {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
    { 'nvim-treesitter/nvim-treesitter-context', opts = { max_lines = 1 } },
    {
      'Wansmer/treesj',
      keys = {
        { 'gJ', '<cmd>TSJToggle<cr>', desc = ' Join Toggle' },
        { 'gS', '<cmd>TSJSplit<cr>', desc = ' Join Split' },
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

        -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
        -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
        -- the name of the parser)
        -- list of language that will be disabled
        -- disable = { 'c', 'rust' },
        -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
        disable = function(lang, buf)
          local ok, stats =
              pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if
              ok
              and stats
              and stats.size > require('commons').constants.big_file_size
          then
            return true
          end
        end,

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
            ['aa'] = { query = '@parameter.outer', desc = '󱘎 outer param' },
            ['ia'] = { query = '@parameter.inner', desc = '󱘎 inner param' },
            ['af'] = { query = '@function.outer', desc = '󱘎 all function' },
            ['if'] = { query = '@function.inner', desc = '󱘎 inner function' },
            ['am'] = { query = '@class.outer', desc = '󱘎 all class' },
            ['im'] = { query = '@class.inner', desc = '󱘎 inner class' },
            ['ac'] = {
              query = '@conditional.outer',
              desc = '󱘎 all conditional',
            },
            ['ic'] = {
              query = '@conditional.inner',
              desc = '󱘎 inner conditional',
            },
            ['aH'] = { query = '@assignment.lhs', desc = '󱘎 assignment lhs' },
            ['aL'] = { query = '@assignment.rhs', desc = '󱘎 assignment rhs' },
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
          goto_next_start = {
            [']m'] = '@function.outer',
            [']M'] = '@class.outer',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[M'] = '@class.outer',
          },
        },
      },

      incremental_selection = {
        enable = true,
      },
      indent = {
        enable = true,
        disable = function(_, buf)
          local ok, stats =
              pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if
              ok
              and stats
              and stats.size > require('commons').constants.big_file_size
          then
            return true
          end
        end,
      },
    }

    -- Mitigate high loading time on big file
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/1100#issuecomment-1762594005
    local isBufSizeBig = require('commons').utils.isBufSizeBig
    vim.api.nvim_create_autocmd('BufReadPre', {
      callback = function()
        if isBufSizeBig(0) then
          vim.wo.foldmethod = 'expr'
        end
      end,
    })
    vim.opt.foldenable = false -- Disable folding at startup.
  end,
}

return M
