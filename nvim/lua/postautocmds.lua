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


