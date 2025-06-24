local M = {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    {
      'nvim-lua/plenary.nvim',
    },
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release',
    },
    {
      'nvim-telescope/telescope-live-grep-args.nvim',
      -- This will not install any breaking changes.
      -- For major updates, this must be adjusted manually.
      version = '^1.0.0',
    },
    { 'gbprod/yanky.nvim' },
    { 'debugloop/telescope-undo.nvim' },
  },
  config = function()
    local builtin = require 'telescope.builtin'
    vim.keymap.set(
      'n',
      '<c-p>',
      builtin.find_files,
      { desc = 'Telescope: find files' }
    )
    vim.keymap.set(
      'n',
      '<leader>ff',
      builtin.find_files,
      { desc = 'Telescope: find files' }
    )
    vim.keymap.set(
      'n',
      '<leader>uu',
      '<cmd>Telescope undo<cr>',
      { desc = '󰚰 Undo Tree' }
    )
    vim.keymap.set(
      'n',
      '<leader>yy',
      '<cmd>Telescope yank_history<cr>',
      { desc = '󰚰 Yank history' }
    )
    vim.keymap.set(
      'n',
      '<leader>fg',
      ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
      { desc = 'Telescope: live grep' }
    )
    vim.keymap.set(
      'n',
      '<leader>fb',
      builtin.buffers,
      { desc = 'Telescope: buffers' }
    )
    vim.keymap.set(
      'n',
      '<leader>fh',
      builtin.help_tags,
      { desc = 'Telescope: help tags' }
    )

    local tls = require 'telescope'

    tls.setup {
      extensions = {
        undo = {
          side_by_side = true,
          layout_strategy = 'vertical',
          layout_config = {
            preview_height = 0.6,
          },
          mappings = {
            i = {
              ['<c-r>'] = require('telescope-undo.actions').yank_additions,
              ['<c-y>'] = require('telescope-undo.actions').yank_deletions,
              ['<cr>'] = require('telescope-undo.actions').restore,
            },
          },
        },
      },
      defaults = {
        file_ignore_patterns = {
          '.git/', -- the slash '/' at the end make sure that only the files inside .git folder are ignored, not the .gitignore, .gitlab-ci.yml, etc which start by '.git' in their names
          'node_modules',
          '__pycache__',
        },
        multi_icon = ' ',
        prompt_prefix = ' ',
        selection_caret = '󱞪 ',
        mappings = {
          n = {
            ['<C-p>'] = require('telescope.actions.layout').toggle_preview,
          },
          i = {
            ['<C-p>'] = require('telescope.actions.layout').toggle_preview,
            ['<C-Down>'] = require('telescope.actions').cycle_history_next,
            ['<C-Up>'] = require('telescope.actions').cycle_history_prev,
            ['<ESC>'] = require('telescope.actions').close,
            ['<C-i>'] = require('telescope.actions').select_horizontal,
            ['<C-s>'] = require('telescope.actions').select_vertical,
          },
        },
        preview = {
          hide_on_startup = true,
        },
      },
      buffers = {
        theme = 'ivy',
      },
      pickers = {
        find_files = {
          theme = 'ivy',
          hidden = true,
        },
      },
    }

    -- Load extensions after calling setup function
    tls.load_extension 'fzf'
    tls.load_extension 'live_grep_args'
  end,
}

return M
