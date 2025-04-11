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
  pattern = { 'qf', 'help' },
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

-- TODO: fix this auto insert mode
vim.cmd [[
autocmd BufReadPost *
\ if !(bufname("%") =~ '\(COMMIT_EDITMSG\)') &&
\   line("'\"") > 1 && line("'\"") < line("$") && &filetype != "svn" |
\   exe "normal! g`\"" |
\ endif
]]
