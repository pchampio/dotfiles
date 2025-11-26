---@module 'lazy'
---@type LazySpec
return {
  event = 'VeryLazy',
  'justinmk/vim-sneak',
  init = function()
    vim.g['sneak#prompt'] = 'Sneak >>> '
    vim.g['sneak#label'] = 1
    vim.g['sneak#use_ic_scs'] = 1
    vim.g['sneak#s_next'] = 1
  end,
  config = function()
    vim.api.nvim_set_hl(0, 'SneakLabel', {
      fg = 'red',
      bold = true,
      underline = true,
    })
    vim.api.nvim_set_hl(0, 'Sneak', { link = 'SneakLabel' })
  end,
  keys = {
    { 'f', '<Plug>Sneak_f', desc = 'Clever-f Forward' },
    { 'F', '<Plug>Sneak_F', desc = 'Clever-f Backward' },
    { 't', '<Plug>Sneak_s', desc = 'Clever-t Forward' },
    { 'T', '<Plug>Sneak_S', desc = 'Clever-t Backward' },
    { ':', '<Plug>Sneak_;', desc = 'Clever-ft repeat' },
  },
}
