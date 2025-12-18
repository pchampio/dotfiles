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

vim.api.nvim_set_hl(0, 'VisualNonText', { fg = '#bebebe', bg = '#d5cdb6' })

local new_bg = vim.api.nvim_get_hl(0, { name = "FoldColumn" }).bg
local diffadd = vim.api.nvim_get_hl(0, { name = "DiffAdd" })
local diffdelete = vim.api.nvim_get_hl(0, { name = "DiffDelete" })
diffadd.bg = new_bg
diffdelete.bg = new_bg
local function set_sidekick_hl()
  vim.api.nvim_set_hl(0, 'SidekickDiffContext', { link = 'NONE' })
  vim.api.nvim_set_hl(0, 'SidekickDiffAdd', diffadd)
  vim.api.nvim_set_hl(0, 'SidekickDiffDelete', diffdelete)
  vim.api.nvim_set_hl(0, 'SidekickSign', { link = 'Comment' })
end

set_sidekick_hl()
