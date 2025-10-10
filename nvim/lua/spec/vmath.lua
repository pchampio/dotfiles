local M = {
  'git@prr.re/Drakirus/vmath.vim.git',
  config = function()
    vim.api.nvim_set_keymap(
      'n',
      '++',
      ':call VMATH_Analyse()<CR>',
      {
        silent = false,
        noremap = true,
        desc = '[+] Simple math on yank buffer',
      }
    )
    vim.api.nvim_set_keymap(
      'v',
      '++',
      'y:call VMATH_Analyse()<CR>',
      {
        silent = false,
        noremap = true,
        desc = '[+] Simple math on visual selection',
      }
    )
  end,
}
return M
