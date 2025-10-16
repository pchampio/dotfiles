local M = {
  'lewis6991/gitsigns.nvim',
  opts = {
    current_line_blame = false,
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
      end, { desc = ' Jump to next diff/hunk' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gs.nav_hunk('prev', { preview = true, navigation_message = true })
        end
      end, { desc = ' Jump to previous diff/hunk' })

      -- Actions
      map('n', '<leader>ha', gs.stage_hunk, { desc = ' Stage Hunk' })
      map('n', '<leader>hr', gs.reset_hunk, { desc = ' Reset Hunk' })

      map('v', '<leader>ha', function()
        gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = ' Stage Hunk Visual' })

      map('v', '<leader>hr', function()
        gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
      end, { desc = ' Reset Hunk Visual' })

      map('n', '<leader>hA', gs.stage_buffer, { desc = ' Stage Buffer' })
      map('n', '<leader>hR', gs.reset_buffer, { desc = ' Reset Buffer' })
      map('n', '<leader>hp', gs.preview_hunk, { desc = ' Preview Hunk' })
      map('n', '<leader>hi', gs.preview_hunk_inline, { desc = ' Preview Hunk Inline' })

      map('n', '<leader>hd', function() gs.diffthis '~' end, { desc = ' Diff Against Last Commit' })

      map('n', '<leader>hQ', function() gs.setqflist 'all' end, { desc = " Open QF list with all modified files" })
      map('n', '<leader>hq', gs.setqflist, { desc = " Open QF list with current modified file" })
      -- Text object
      map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = ' Select Hunk' })
    end,
  },
}

return M
