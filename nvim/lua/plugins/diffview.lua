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
            focus_explorer = "<leader>e",
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
          vim.o.showtabline = 0

          local diff_tab = vim.api.nvim_get_current_tabpage()
          local diff_wins = {}
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(diff_tab)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype ~= "codediff-explorer" then
              diff_wins[win] = true
              vim.wo[win].cursorline = false
            end
          end

          local group = vim.api.nvim_create_augroup("CodeDiffCursorline", { clear = true })

          vim.api.nvim_create_autocmd({"WinEnter", "BufEnter"}, {
            group = group,
            callback = function()
              if not vim.api.nvim_tabpage_is_valid(diff_tab) then
                return true
              end
              if diff_wins[vim.api.nvim_get_current_win()] then
                vim.wo.cursorline = false
              else
                vim.wo.cursorline = true
              end
            end,
          })

          vim.api.nvim_create_autocmd("User", {
            pattern = "CodeDiffFileSelect",
            group = group,
            callback = function()
              if not vim.api.nvim_tabpage_is_valid(diff_tab) then
                return true
              end
              diff_wins = {}
              for _, win in ipairs(vim.api.nvim_tabpage_list_wins(diff_tab)) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.bo[buf].filetype ~= "codediff-explorer" then
                  diff_wins[win] = true
                  vim.wo[win].cursorline = false
                end
              end
            end,
          })
        end,
      })

    end,
  }
}
