local M = {
  'machakann/vim-sandwich',
  priority = 100,
  init = function()
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
      desc = '󰗅 Add surrounding character',
    },
    {
      mode = { 'n', 'x' },
      'SS',
      '<Plug>(operator-sandwich-add)line',
      desc = '󰗅  Add surrounding character line',
    },
    {
      mode = { 'n' },
      'ds',
      '<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)',
      desc = '󰗅  Delete surrounding character',
    },
    {
      mode = { 'n' },
      'dss',
      '<Plug>(operator-sandwich-delete)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)',
      desc = '󰗅  Delete surrounding character automatically',
    },
    {
      mode = { 'n' },
      'din',
      'd<Plug>(textobj-sandwich-literal-query-i)',
      desc = '󰗅  Delete surrounding inside surrounding character prompt',
    },
    {
      mode = { 'n' },
      'dan',
      'd<Plug>(textobj-sandwich-literal-query-a)',
      desc = '󰗅  Delete surrounding around surrounding character prompt',
    },
    {
      mode = { 'n' },
      'cs',
      '<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-query-a)',
      desc = '󰗅  Change surrounding character',
    },
    {
      mode = { 'n' },
      'css',
      '<Plug>(operator-sandwich-replace)<Plug>(operator-sandwich-release-count)<Plug>(textobj-sandwich-auto-a)',
      desc = '󰗅  Change surrounding character automatically',
    },
    {
      mode = { 'x', 'o' },
      'is',
      '<Plug>(textobj-sandwich-query-i)',
      desc = '󰗅  Select inside surrounding character',
    },
    {
      mode = { 'x', 'o' },
      'as',
      '<Plug>(textobj-sandwich-query-a)',
      desc = '󰗅  Select around surrounding character',
    },
    {
      mode = { 'x', 'o' },
      'ii',
      '<Plug>(textobj-sandwich-auto-i)',
      desc = '󰗅  Select inside surrounding character automatically',
    },
    {
      mode = { 'x', 'o' },
      'ai',
      '<Plug>(textobj-sandwich-auto-a)',
      desc = '󰗅  Select around surrounding character automatically',
    },
    {
      mode = { 'n' },
      'cin',
      'c<Plug>(textobj-sandwich-literal-query-i)',
      desc = '󰗅  Select inside surrounding character prompt',
    },
    {
      mode = { 'n' },
      'can',
      'c<Plug>(textobj-sandwich-literal-query-a)',
      desc = '󰗅  Select around surrounding character prompt',
    },
    {
      mode = { 'x', 'o' },
      'in',
      '<Plug>(textobj-sandwich-literal-query-i)',
      desc = '󰗅  Select inside surrounding character prompt',
    },
    {
      mode = { 'x', 'o' },
      'an',
      '<Plug>(textobj-sandwich-literal-query-a)',
      desc = '󰗅  Select around surrounding character prompt',
    },
  },
}

return M
