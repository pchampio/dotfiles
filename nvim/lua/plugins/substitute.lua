---@module 'lazy'
---@type LazySpec
return {
  event = 'VeryLazy',
  'gbprod/substitute.nvim',
  dependencies = { 'gbprod/yanky.nvim', 'tpope/vim-abolish' },
  config = function()
    require('substitute').setup {
      on_substitute = require('yanky.integration').substitute(),
      highlight_substituted_text = {
        enabled = true,
        timer = 250,
      },
      range = {
        prefix = 'r',
      },
    }
    vim.cmd [[hi SubstituteRange guifg=#37afd3 gui=underline,bold]]
    vim.cmd [[hi SubstituteExchange guifg=#37afd3 gui=underline,bold]]
    vim.keymap.set({ 'x', 'n' }, 'r', require('substitute').operator, { noremap = true, desc = "󰛔  Replace" })
    vim.keymap.set('n', 'rr', require('substitute').line, { noremap = true, desc = "󰛔  Replace" })
    vim.keymap.set('n', 'cx', require('substitute.exchange').operator, { noremap = true, desc = "󰛔  Exchange" })
    vim.keymap.set('n', 'cxx', require('substitute.exchange').line, { noremap = true, desc = "󰛔  Exchange Line" })
    vim.keymap.set('x', 'X', require('substitute.exchange').visual, { noremap = true, desc = "󰛔  Exchange Visual" })
    vim.keymap.set('n', 'cxc', require('substitute.exchange').cancel, { noremap = true, desc = "󰛔  Exchange Cancel" })
    vim.keymap.set('n', '<leader>S', function()
      require('substitute.range').operator { prefix = 'S' }
    end, { noremap = true, desc = "󰛔  Substitute Range" })
    vim.api.nvim_set_keymap('o', 'iE', ':exec "normal! ggVG"<cr>', { silent = true, noremap = true, desc = 'Inner Entire Buffer' })
    vim.keymap.set({ 'n', 'v' }, 'R', 'r', { noremap = true }) -- map R to old r behavior
  end,
}
