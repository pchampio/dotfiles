---@module 'lazy'
---@type LazySpec
return {
  event = 'VeryLazy',
  'machakann/vim-sandwich',
  config = function()
    vim.cmd [[ onoremap line :normal! ^vg_<CR> ]]
    vim.g.sandwich_no_default_key_mappings = 1
    vim.g.operator_sandwich_no_default_key_mappings = 1
    vim.g.textobj_sandwich_no_default_key_mappings = 1
  end,
  keys = {
    {
      mode = { 'n', 'x' },
      'S',
      '<Plug>(operator-sandwich-add)',
      desc = '󰗅  Add S. Character',
    },
    {
      mode = { 'n', 'x' },
      'SS',
      'g^<Plug>(operator-sandwich-add)$',
      desc = '󰗅  Add S. Line',
    },
    {
      mode = { 'n' },
      'ds',
      '<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)',
      desc = '󰗅  Del. S. Character',
    },
    {
      mode = { 'n' },
      'dss',
      '<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)',
      desc = '󰗅  Del. S. Character found',
    },
    {
      mode = { 'n' },
      'din',
      'd<Plug>(textobj-sandwich-literal-query-i)',
      desc = '󰗅  Del. S. Inside S. Prompt',
    },
    {
      mode = { 'n' },
      'dan',
      'd<Plug>(textobj-sandwich-literal-query-a)',
      desc = '󰗅  Del. S. Around S. Prompt',
    },
    {
      mode = { 'n' },
      'cs',
      '<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)',
      desc = '󰗅  Change S. Character',
    },
    {
      mode = { 'n' },
      'css',
      '<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)',
      desc = '󰗅  Change S. Character found',
    },
    {
      mode = { 'x', 'o' },
      'is',
      '<Plug>(textobj-sandwich-query-i)',
      desc = '󰗅  Select Inside S. Character',
    },
    {
      mode = { 'x', 'o' },
      'as',
      '<Plug>(textobj-sandwich-query-a)',
      desc = '󰗅  Select Around S. Character',
    },
    {
      mode = { 'x', 'o' },
      'ii',
      '<Plug>(textobj-sandwich-auto-i)',
      desc = '󰗅  Select Inside S. Found',
    },
    {
      mode = { 'x', 'o' },
      'ai',
      '<Plug>(textobj-sandwich-auto-a)',
      desc = '󰗅  Select Around S. Found',
    },
    {
      mode = { 'n' },
      'cin',
      'c<Plug>(textobj-sandwich-literal-query-i)',
      desc = '󰗅  Select Inside S. Prompt',
    },
    {
      mode = { 'n' },
      'can',
      'c<Plug>(textobj-sandwich-literal-query-a)',
      desc = '󰗅  Select Around S. Prompt',
    },
    {
      mode = { 'x', 'o' },
      'in',
      '<Plug>(textobj-sandwich-literal-query-i)',
      desc = '󰗅  Select Inside S. Prompt',
    },
    {
      mode = { 'x', 'o' },
      'an',
      '<Plug>(textobj-sandwich-literal-query-a)',
      desc = '󰗅  Select Around S. Prompt',
    },
  },
}
