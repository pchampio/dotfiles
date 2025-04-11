local options = {
  completeopt = { 'menuone', 'noselect' }, -- show popup menu even when there is only one match and no item is pre-selected
  pumheight = 10,                          -- maximum popup menu items
  ignorecase = true,                       -- ignore case in search patterns
  smartcase = true,                        -- case sensitive only when there is at least one uppercase letter in search patterns
  mouse = 'a',                             -- allow the mouse usage
  showcmd = false,                         -- hide (partial) command in the last line of the screen (for performance)
  showmode = false,                        -- hide things like -- INSERT --
  splitbelow = true,                       -- force all horizontal splits to go below current window
  splitright = true,                       -- force all vertical splits to go to the right of current window
  swapfile = false,                        -- don't create a swapfile
  undofile = true,                         -- enable persistent undo
  undodir = vim.fn.expand '~/.vim_undo',
  shada = "'100,<50,s10,:1000,/100,@100,h",
  shadafile = vim.fn.expand '~/.vim_shada',
  expandtab = true,                         -- convert tabs to spaces
  shiftround = true,                        -- round indent to multiple of 'shiftwidth'
  shiftwidth = 2,                           -- number of spaces inserted for each indentation
  tabstop = 2,                              -- number of spaces for a tab
  cursorline = true,                        -- highlight the current line
  number = true,                            -- show line numbers
  relativenumber = true,                    -- show relative line numbers
  laststatus = 3,                           -- only the last window will always have a status line
  signcolumn = 'yes',                       -- always show the sign column, otherwise it would shift the text each time
  linebreak = true,                         -- wrap long lines at a character in 'breakat' rather than at the last character that fits on the screen
  scrolloff = 4,                            -- minimum number of screen lines to keep above and below the cursor
  sidescrolloff = 7,
  colorcolumn = '80',                       -- ruler
  backspace = { 'indent', 'eol', 'start' }, -- Enable backspace delete indent and newline.
  breakindent = true,
  list = true,                              -- display extra whitespace
  listchars = 'tab:▸\\ ,trail:·,extends:›,precedes:‹',
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.wo.wrap = false

-- Exclude = from isfilename.
vim.opt.isfname:remove '='
-- Exclude : from isfilename.
vim.opt.isfname:remove ':'

-- Mitigate high loading time on big file
-- Tests with value 0 show that these do not take affect, so choose value 1
vim.g.matchparen_timeout = 1        -- https://github.com/neovim/neovim/blob/master/runtime/plugin/matchparen.vim#L15
vim.g.matchparen_insert_timeout = 1 -- https://github.com/neovim/neovim/blob/master/runtime/plugin/matchparen.vim#L18

-- Capture the diff mode flag globally because tests show that when nvim is
-- opened in diff mode (e.g. via git difftool, nvim -d, etc), a ftplugin script
-- is called as many times as the number of buffers opened for diff viewing, and
-- it seems like vim.o.diff (or vim.opt.diff:get()) returns true only on the
-- first time a ftplugin script is called, subsequent calls result in false to
-- be returned, which makes this api not appropriate to be used in ftplugin
-- scripts when nvim is in diff mode
vim.g.diffmode = vim.o.diff

-- Lower y yank to/from * by default (tmux only, not system)
vim.o.clipboard = 'unnamed'
-- Upper Y yank to system clipboard
vim.g.clipboard = {
  copy = {
    ['+'] = 'env COPY_PROVIDERS=desktop '
        .. vim.fn.expand '~'
        .. '/dotfiles/bin/clipboard-provider copy',
    ['*'] = 'env COPY_PROVIDERS=tmux '
        .. vim.fn.expand '~'
        .. '/dotfiles/bin/clipboard-provider copy',
  },
  paste = {
    ['+'] = 'env PASTE_PROVIDERS=desktop '
        .. vim.fn.expand '~'
        .. '/dotfiles/bin/clipboard-provider paste',
    ['*'] = 'env PASTE_PROVIDERS=tmux '
        .. vim.fn.expand '~'
        .. '/dotfiles/bin/clipboard-provider paste',
  },
}
