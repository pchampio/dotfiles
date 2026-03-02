---@module 'lazy'
---@type LazySpec
return {
  {
    'whiteinge/diffconflicts',
    cmd = 'DiffConflicts',
  }, {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("codediff").setup({
        highlights = {
          line_insert = "#c5ebb2",
          line_delete = "#f5c2bf",
          char_insert = "#91cc74",
          char_delete = "#f58982",
        },
        -- explorer = {
        --   position = "bottom",
        --   height = 3,
        -- },
        keymaps = {
          view = {
            quit = "q",                    -- Close diff tab
            toggle_explorer = "<leader>b",  -- Toggle explorer visibility (explorer mode only)
            next_hunk = "]c",   -- Jump to next change
            prev_hunk = "[c",   -- Jump to previous change
            next_file = "<Down>",   -- Next file in explorer mode
            prev_file = "<Up>",   -- Previous file in explorer mode
            diff_get = "do",    -- Get change from other buffer (like vimdiff)
            diff_put = "dp",    -- Put change to other buffer (like vimdiff)
          }
        }
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeDiffOpen",
        callback = function()
          -- Hide tabline while CodeDiff is open
          vim.o.showtabline = 0
          -- Disable cursorline in diff windows
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype ~= "codediff-explorer" then 
              vim.wo[win].cursorline = false
            end
          end
        end,
      })

    end,
  }
}
