local M = {
  'lewis6991/gitsigns.nvim',
  opts = {
    current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
      delay = 0,
    },
    on_attach = function(bufnr)
      local gs = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gs.nav_hunk('next', { preview = true, navigation_message = true })
        end
      end, { desc = ' jump to next hunk' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gs.nav_hunk('prev', { preview = true, navigation_message = true })
        end
      end, { desc = ' jump to previous hunk' })

      -- Actions
      map('n', '<leader>ha', gs.stage_hunk, { desc = ' stage hunk' })
      map('n', '<leader>hr', gs.reset_hunk, { desc = ' reset hunk' })

      map('v', '<leader>ha', function()
        gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = ' stage hunk' })

      map('v', '<leader>hr', function()
        gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = ' reset hunk' })

      map(
        'n',
        '<leader>hA',
        gs.stage_buffer,
        { desc = ' stage buffer' }
      )
      map(
        'n',
        '<leader>hR',
        gs.reset_buffer,
        { desc = ' reset buffer' }
      )
      map(
        'n',
        '<leader>hp',
        gs.preview_hunk,
        { desc = ' preview hunk' }
      )
      map(
        'n',
        '<leader>hi',
        gs.preview_hunk_inline,
        { desc = ' preview hunk inline' }
      )

      map('n', '<leader>hb', function()
        gs.blame_line { full = true }
      end, { desc = ' blame line' })

      map('n', '<leader>hd', function()
        gs.diffthis '~'
      end, { desc = ' diff against the last commit' })

      map('n', '<leader>hQ', function()
        gs.setqflist 'all'
      end, {
        desc = " open qf list populated with all modified files' hunks",
      })
      map('n', '<leader>hq', gs.setqflist, {
        desc = " open qf list populated with current file's hunks",
      })

      -- Toggles
      map(
        'n',
        '<leader>htb',
        gs.toggle_current_line_blame,
        { desc = ' toggle current line blame' }
      )
      map(
        'n',
        '<leader>htw',
        gs.toggle_word_diff,
        { desc = ' toggle word diff' }
      )

      -- Text object
      map(
        { 'o', 'x' },
        'ih',
        ':<C-U>Gitsigns select_hunk<CR>',
        { desc = ' select hunk' }
      )
    end,
  },
}

return M
