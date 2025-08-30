vim.api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { timeout = 150 }
  end,
})

vim.cmd [[
  hi YankyYankedTmux guifg=#d33682 gui=underline,bold
  hi YankyYankedSystem guifg=#366ad3 gui=underline,bold
]]
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('HighlightYank', {}),
  pattern = '*',
  callback = function()
    if vim.v.event.regname == '+' then
      vim.highlight.on_yank {
        higroup = 'YankyYankedSystem',
        timeout = 250,
      }
    else
      vim.highlight.on_yank {
        higroup = 'YankyYankedTmux',
        timeout = 250,
      }
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'qf', 'help', 'checkhealth' },
  callback = function()
    vim.opt_local.colorcolumn = ''
  end,
})

vim.api.nvim_create_autocmd('BufReadPre', {
  callback = function()
    if require('commons').utils.isBufSizeBig(0) then
      vim.treesitter.stop()
    end
    vim.schedule(function()
      vim.opt_local.indentexpr = ''
    end)
    vim.opt_local.syntax = 'OFF'

    if pcall(require, 'ibl') then
      vim.cmd 'IBLDisable'
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'gitcommit',
  callback = function()
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
