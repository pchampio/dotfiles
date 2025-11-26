
--- Get the hunk at the current cursor position
--- @return Gitsigns.Hunk.Hunk|nil The hunk at cursor, or nil if no hunk found
--- @return integer|nil The index of the hunk in the hunks array
local function get_hunk_under_cursor()
    local gs = require('gitsigns')
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    local hunks = gs.get_hunks()

    if not hunks then
        return nil, nil
    end

    for i, hunk in ipairs(hunks) do
        -- Handle topdelete hunks (deleted lines at start of file)
        if cursor_line == 1 and hunk.added.start == 0 and hunk.vend == 0 then
            return hunk, i
        end

        vim.notify(vim.inspect(hunk.added.start))
        vim.notify(vim.inspect(cursor_line))
        if hunk.added.start == cursor_line then
            return hunk, i
        end
    end

    return nil, nil
end

---@module 'lazy'
---@type LazySpec
return {
  'lewis6991/gitsigns.nvim',
  config = function()
    ---@module 'gitsigns.gh'
    local gs = require 'gitsigns'

    vim.g.gitsigns_nav_target = 'unstaged'

    local function nav_with_conditional_preview(direction)
      local startline = vim.api.nvim_win_get_cursor(0)[1]
      gs.nav_hunk(direction, { preview = false, target = vim.g.gitsigns_nav_target, navigation_message = true })
      vim.defer_fn(function()
        vim.cmd('redraw!')
        if vim.api.nvim_win_get_cursor(0)[1] ~= startline then
        vim.notify(vim.inspect(get_hunk_under_cursor()))
          -- gs.preview_hunk()
      end  
      end, 200)
    end

    -- Navigation for all
    vim.keymap.set('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        nav_with_conditional_preview('next')
      end
    end, { desc = '  Jump to next diff/hunk' })
    vim.keymap.set('n', ']C', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        nav_with_conditional_preview('prev')
      end
    end, { desc = '_  Jump to previous diff/hunk' })

    vim.keymap.set('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        nav_with_conditional_preview('prev')
      end
    end, { desc = '   Jump to previous diff/hunk' })
    vim.keymap.set('n', '[C', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        nav_with_conditional_preview('next')
      end
    end, { desc = '_ Jump to next diff/hunk' })

    local opts = {
      preview_config = {
        border = 'rounded',
        relative = 'win',
        row = 4,
        col = 12,
      },
      current_line_blame = false,
      current_line_blame_opts = {
        delay = 200,
        virt_text_pos = 'right_align',
      },
      on_attach = function(bufnr)
        -- Actions
        -- - nvim_feedkeys 27 is for hiding the floating text git diff
        vim.keymap.set('n', '<leader>ha', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.stage_hunk() end, { desc = '', buffer = bufnr })
        vim.keymap.set('n', ']a', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.stage_hunk() end, { desc = '_GIT: Add/Unadd Hunk', buffer = bufnr })
        vim.keymap.set('n', '[a', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.stage_hunk() end, { desc = '_GIT: Add/Unadd Hunk', buffer = bufnr })
        vim.keymap.set('n', '<leader>hr', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.reset_hunk() end, { desc = '', buffer = bufnr })
        vim.keymap.set('n', ']r', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.reset_hunk() end, { desc = '_GIT: Reset Hunk', buffer = bufnr })
        vim.keymap.set('n', '[r', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.reset_hunk() end, { desc = '_GIT: Reset Hunk', buffer = bufnr })
        vim.keymap.set('n', '<leader>hu', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.reset_hunk() end, { desc = '', buffer = bufnr })
        vim.keymap.set('n', ']u', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.reset_hunk() end, { desc = '_GIT: Reset Hunk', buffer = bufnr })
        vim.keymap.set('n', '[u', function() vim.api.nvim_feedkeys('\27', 'mit', false) gs.reset_hunk() end, { desc = '_GIT: Reset Hunk', buffer = bufnr })

        vim.keymap.set('v', '<leader>ha', function() gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '', buffer = bufnr })

        vim.keymap.set('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '', buffer = bufnr })
        vim.keymap.set('v', '<leader>hu', function() gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = '', buffer = bufnr })

        vim.keymap.set('n', '<leader>hA', gs.stage_buffer, { desc = 'GIT: Stage Buffer', buffer = bufnr })
        vim.keymap.set('n', '<leader>hR', gs.reset_buffer, { desc = 'GIT: Reset Buffer', buffer = bufnr })
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { desc = 'GIT: Preview Hunk', buffer = bufnr })
        vim.keymap.set('n', ']p', gs.preview_hunk, { desc = '_GIT: Preview Hunk', buffer = bufnr })
        vim.keymap.set('n', '[p', gs.preview_hunk, { desc = '_GIT: Preview Hunk', buffer = bufnr })
        vim.keymap.set('n', '<leader>hi', gs.preview_hunk_inline, { desc = 'GIT: Preview Hunk Inline', buffer = bufnr })

        vim.keymap.set('n', '<leader>hd', function() gs.diffthis '~' end, { desc = 'GIT: Diff Against Last Commit', buffer = bufnr })

        vim.keymap.set('n', '<leader>hQ', function() gs.setqflist 'all' end, { desc = 'GIT: QF modified files', buffer = bufnr })
        vim.keymap.set('n', '<leader>hq', gs.setqflist, { desc = 'GIT: qF list this file', buffer = bufnr })
        -- Text object
        vim.keymap.set({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'GIT: Select Hunk', buffer = bufnr })
      end,
    }
    require('gitsigns').setup(opts)
  end,
}
