local options = {
  completeopt = { 'menuone', 'noselect' }, -- Show popup menu even when there is only one match and no item is pre-selected
  pumheight = 10,                          -- Maximum popup menu items
  ignorecase = true,                       -- Ignore case in search patterns
  smartcase = true,                        -- Case sensitive only when there is at least one uppercase letter in search patterns
  mouse = 'a',                             -- Allow the mouse usage
  showcmd = false,                         -- Hide (partial) command in the last line of the screen (for performance)
  showmode = false,                        -- Hide things like '-- INSERT --'
  splitbelow = true,                       -- Force all horizontal splits to go below current window
  splitright = true,                       -- Force all vertical splits to go to the right of current window
  swapfile = false,                        -- Don't create a swapfile
  undofile = true,                         -- Enable persistent undo
  undodir = vim.fn.expand '~/.vim_undo',
  shada = "'100,<50,s10,:1000,/100,@100,h",
  shadafile = vim.fn.expand '~/.vim_shada',
  expandtab = true,                         -- Convert tabs to spaces
  shiftround = true,                        -- Round indent to multiple of 'shift width'
  shiftwidth = 2,                           -- Number of spaces inserted for each indentation
  tabstop = 2,                              -- Number of spaces for a tab
  cursorline = true,                        -- Highlight the current line
  -- comfy line number
  statuscolumn = "  ",                      -- Empty to avoid number from being modified during startup
  number = true,                            -- Show line numbers
  relativenumber = false,                   -- Show relative line numbers
  numberwidth = 5,                          -- This avoid a visual distraction when loading
  laststatus = 3,                           -- Only the last window will always have a status line
  signcolumn = 'yes',                       -- Always show the sign column, otherwise it would shift the text each time
  linebreak = true,                         -- Wrap long lines at a character in 'break at' rather than at the last character that fits on the screen
  scrolloff = 4,                            -- Minimum number of screen lines to keep above and below the cursor
  sidescrolloff = 7,
  synmaxcol = 500,                          -- Limit max column for syntax highlighting to mitigate high loading time on big file
  colorcolumn = '80',                       -- Ruler
  backspace = { 'indent', 'eol', 'start' }, -- Enable backspace delete indent and newline.
  breakindent = true,
  list = true,                              -- Display extra whitespace
  listchars = {
    nbsp = '⦸',
    extends = '»',
    precedes = '«',
    tab = '▸\\ ',
    trail = '·',
  },
  termguicolors = true,
  foldenable = false, -- Disable folding at startup.
  statusline = "%#Visual#%<    %t", -- Mimic lualine statusline, avoid flicker at startup
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

vim.wo.wrap = false

vim.g.mapleader = ','
vim.gmaplocalleader = ','

-- Exclude = from isfilename.
vim.opt.isfname:remove '='
-- Exclude : from isfilename.
vim.opt.isfname:remove ':'

-- Mitigate high loading time on big file
-- Tests with value 0 show that these do not take affect, so choose value 1
vim.g.matchparen_timeout = 1        -- https://github.com/neovim/neovim/blob/master/runtime/plugin/matchparen.vim#L15
vim.g.matchparen_insert_timeout = 1 -- https://github.com/neovim/neovim/blob/master/runtime/plugin/matchparen.vim#L18

-- Lower y yank to/from * by default (tmux only, not system)
vim.o.clipboard = 'unnamed'
-- Upper Y yank to system clipboard
local is_tmux = os.getenv 'TMUX' ~= nil

-- Define the clipboard configuration
local clipboard_provider_path = vim.fn.expand '~'
    .. '/dotfiles/bin/clipboard-provider'
local clipboard_config = {
  copy = {
    ['+'] = 'env COPY_PROVIDERS=desktop ' .. clipboard_provider_path .. ' copy',
  },
  paste = {
    ['+'] = 'env PASTE_PROVIDERS=desktop '
        .. clipboard_provider_path
        .. ' paste',
  },
}

-- Add tmux-specific configuration if tmux is running
if is_tmux then
  clipboard_config.copy['*'] = 'env COPY_PROVIDERS=tmux '
      .. clipboard_provider_path
      .. ' copy'
  clipboard_config.paste['*'] = 'env PASTE_PROVIDERS=tmux '
      .. clipboard_provider_path
      .. ' paste'
else
  clipboard_config.copy['*'] = function(lines, regtype)
    -- Store clipboard in vim var instead of tmux var
    vim.g.prr_internal_clip_board = { lines, regtype }
  end
  clipboard_config.paste['*'] = function()
    return vim.g.prr_internal_clip_board or {}
  end
end

-- Set the clipboard configuration
vim.g.clipboard = clipboard_config

-- By default disable watchman integration for Command-T
vim.g.commandt_cmd_watchman = false

-- Default severities to show for diagnostics
vim.g.diagnostic_severities = { vim.diagnostic.severity.WARN, vim.diagnostic.severity.ERROR }

-- Configure signs and text for severity (order matters for next severity)
vim.g.diagnostic_severities_signs = {
  {level = vim.diagnostic.severity.ERROR, sign = '✘', text = 'Error Only' },
  {level = vim.diagnostic.severity.WARN,  sign = '', text = 'Error + Warning' },
  {level = vim.diagnostic.severity.INFO,  sign = '◉', text = 'Error + Warning + Info' },
  {level = vim.diagnostic.severity.HINT,  sign = '⚑', text = 'All Diagnostics' },
}


-- Hide some floating windows with Esc
vim.keymap.set('n', '<esc>', require('commons').smart_hide_floating_window )

-- Experimental: highlight cmdline, messages in a real buffer.
-- See https://github.com/neovim/neovim/pull/27811 and :help vim._extui
-- NOTE: Use 'g<' to see more messages!
vim.schedule(function()
  require('vim._extui').enable {
    enable = true,
  }
end)
