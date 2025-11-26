---@module 'lazy'
---@type LazySpec
return {
  'pchampio/vim-edgemotion',
    keys = {
      { "J", "<Plug>(edgemotion-j)", mode = {"v","n"}, noremap = false, silent = true },
      { "K", "<Plug>(edgemotion-k)", mode = {"v","n"}, noremap = false, silent = true },
    }
}
