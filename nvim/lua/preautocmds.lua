vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'qf', 'help', 'checkhealth' },
  callback = function()
    vim.opt_local.colorcolumn = ''
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'gitcommit' },
  callback = function()
    vim.opt_local.colorcolumn = '50,72'
    vim.cmd 'startinsert'
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local last_pos = vim.api.nvim_buf_get_mark(0, '"')
    local line = last_pos[1]
    if line > 0
       and line <= vim.api.nvim_buf_line_count(0)
       and vim.bo.buftype == ""
       and vim.bo.filetype ~= "gitcommit"
       and vim.bo.filetype ~= "help"
    then
      vim.api.nvim_win_set_cursor(0, last_pos)
    end
  end,
})
