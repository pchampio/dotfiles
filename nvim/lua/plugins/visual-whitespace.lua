return {
  'mcauley-penney/visual-whitespace.nvim',
  event = 'ModeChanged *:[vV\22]', -- optionally, lazy load on entering visual mode
  config = function()
    require('visual-whitespace').setup {
      match_types = {
        space = true,
        tab = false,
        nbsp = false,
      },
      list_chars = {
        space = '·',
        tab = '▸ ',
        nbsp = '␣',
        lead = '‹',
        trail = '›',
      },
      fileformat_chars = {
        unix = "",
        mac = "",
        dos = "",
      },
    }
  end,
}
