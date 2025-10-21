---@module 'lazy'
---@type LazySpec
local M = {
  'pchampio/vim-edgemotion',
  config = function()
    vim.api.nvim_set_keymap(
      '',
      'J',
      '<Plug>(edgemotion-j)',
      { desc = '[J] Edgemotion Down' }
    )
    vim.api.nvim_set_keymap(
      '',
      'K',
      '<Plug>(edgemotion-k)',
      { desc = '[K] Edgemotion Up' }
    )
  end,
}
return M
