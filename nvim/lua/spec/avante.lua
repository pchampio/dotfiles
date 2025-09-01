-- Define a function to set the Avante highlights
local function set_avante_highlights()
  -- Link groups to standard Diff highlight groups
  vim.api.nvim_set_hl(
    0,
    'AvanteToBeDeletedWOStrikethrough',
    { link = 'DiffDelete' }
  )
  vim.api.nvim_set_hl(0, 'AvanteConflictIncoming', { link = 'DiffAdd' })
  vim.api.nvim_set_hl(0, 'AvanteConflictCurrent', { link = 'DiffCurrent' })
  vim.api.nvim_set_hl(0, 'AvanteConflictCurrentLabel', { link = 'DiffText' })
  vim.api.nvim_set_hl(0, 'AvanteConflictIncomingLabel', { link = 'DiffText' })
  vim.api.nvim_set_hl(0, 'AvantePromptInput', { link = 'Comment' })
end

-- Create an autocommand to reapply these settings when the colorscheme changes
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = set_avante_highlights,
})

set_avante_highlights()

local M = {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  lazy = true,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    provider = 'copilot',
    behaviour = {
      enable_token_counting = false,
    },
    input = {
      provider = 'snacks',
      provider_opts = {
        title = 'Avante Input',
        icon = ' ',
      },
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',
  dependencies = {
    'nvim-lua/plenary.nvim',
    "folke/snacks.nvim",
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    -- "hrsh7th/nvim-cmp",          -- autocompletion for avante commands and mentions
    'nvim-mini/mini.icons',
    {
      'zbirenbaum/copilot.lua',
      init = function()
        require('copilot').setup {
          -- copilot_model = 'gpt-4o-copilot',
        }
      end,
    }, -- for providers='copilot'
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
}

return M
