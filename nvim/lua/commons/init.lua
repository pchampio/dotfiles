local M = {
  utils = {
    map = function(mode, lhs, rhs, opts)
      local options = { noremap = true, silent = true }
      if opts then
        options = vim.tbl_extend('force', options, opts)
      end
      vim.keymap.set(mode, lhs, rhs, options)
    end,
  },
  servers = {
    'lua_ls',
    'html',
    'cssls',
    'ts_ls',
    'clangd',
    'bashls',
    'yamlls',
    'ruff',
    'basedpyright',
    'harper_ls',
    'copilot-language-server',
    'stylua',
  },
}

function M.utils.rhs(rhs_str)
  return vim.api.nvim_replace_termcodes(rhs_str, true, true, true)
end

function M.smart_hide_floating_window()
  for _, id in ipairs(vim.api.nvim_list_wins()) do
    local win_config = vim.api.nvim_win_get_config(id)
    if win_config.relative ~= "" then
      ------------------------
      -- Config based close --
      ------------------------
      -- Snacks Notification History close
      if win_config.title and win_config.title[1][1] == " Notification History " then
        vim.api.nvim_win_close(id, false)
        break
      end
      -------------------------
      -- Content based close --
      -------------------------
      -- GitSigns/Diagnostics preview close
      local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(id), 0, -1, false)
      if lines[1] and (lines[1]:match("^Hunk") or lines[1]:match("^Diagnostics:") ) then
        vim.api.nvim_win_close(id, false)
        break
      end
      -- Lazy.nvim floating window close
      if lines[2] and lines[2]:match("Install.*%(I%).*Update.*%(U%).*Sync.*%(S%)") then
        vim.api.nvim_win_close(id, false)
        break
      end
    end
  end
end

return M
