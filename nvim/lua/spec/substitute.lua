local M = {
  'gbprod/substitute.nvim',
  dependencies = { 'gbprod/yanky.nvim', 'tpope/vim-abolish' },
  config = function()
    -- Upper Y yank to system clipboard
    vim.keymap.set('n', 'YY', '"+yy', { silent = true, noremap = true })
    vim.keymap.set('', 'Y', '"+y', { silent = true, noremap = true })

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
    vim.keymap.set(
      { 'x', 'n' },
      'r',
      require('substitute').operator,
      { noremap = true }
    )
    vim.keymap.set('n', 'rr', require('substitute').line, { noremap = true })
    vim.keymap.set('x', 's', require('substitute').visual, { noremap = true })
    vim.keymap.set(
      'n',
      'rx',
      require('substitute.exchange').operator,
      { noremap = true }
    )
    vim.keymap.set(
      'n',
      'rxx',
      require('substitute.exchange').line,
      { noremap = true }
    )
    vim.keymap.set(
      'x',
      'X',
      require('substitute.exchange').visual,
      { noremap = true }
    )
    vim.keymap.set(
      'n',
      'rxc',
      require('substitute.exchange').cancel,
      { noremap = true }
    )
    vim.keymap.set(
      'n',
      '<leader>r',
      require('substitute.range').operator,
      { noremap = true }
    )
    vim.keymap.set(
      'x',
      '<leader>r',
      require('substitute.range').visual,
      { noremap = true }
    )
    vim.keymap.set(
      'n',
      '<leader>rr',
      require('substitute.range').word,
      { noremap = true }
    )
    vim.keymap.set('n', '<leader>S', function()
      require('substitute.range').operator { prefix = 'S' }
    end, { noremap = true })
    vim.api.nvim_set_keymap(
      'o',
      'iE',
      ':exec "normal! ggVG"<cr>',
      { silent = true, noremap = true, desc = 'inner entire buffer' }
    )
    vim.keymap.set({ 'n', 'v' }, 'R', 'r', { noremap = true }) -- map R to old r behavior
    vim.keymap.set(
      'n',
      'cx',
      require('substitute.exchange').operator,
      { noremap = true }
    )
    vim.keymap.set(
      'n',
      'cxx',
      require('substitute.exchange').line,
      { noremap = true }
    )
    vim.keymap.set(
      'x',
      'X',
      require('substitute.exchange').visual,
      { noremap = true }
    )
    vim.keymap.set(
      'n',
      'cxc',
      require('substitute.exchange').cancel,
      { noremap = true }
    )
  end,
}

return M
