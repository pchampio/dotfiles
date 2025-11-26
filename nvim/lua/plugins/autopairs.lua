---@module 'lazy'
---@type LazySpec
return {
  event = "VeryLazy",
  'windwp/nvim-autopairs',
  dependencies = {
    'hrsh7th/nvim-cmp',
  },
  config = function()
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    local cmp = require 'cmp'
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

    local npairs = require 'nvim-autopairs'
    npairs.setup()
  end,
}
