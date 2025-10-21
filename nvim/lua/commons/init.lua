local M = {
  constants = {
    big_file_size = 50 * 1024, -- 50 KB
  },
  utils = {
    map = function(mode, lhs, rhs, opts)
      local options = { noremap = true, silent = true }
      if opts then
        options = vim.tbl_extend('force', options, opts)
      end
      vim.keymap.set(mode, lhs, rhs, options)
    end,
  },
  servers = {
    'lua_ls',
    'html',
    'cssls',
    'ts_ls',
    'clangd',
    'bashls',
    'yamlls',
    'ruff',
    'basedpyright',
    'harper_ls',
    'copilot-language-server',
    'stylua'
  },
}

function M.utils.rhs(rhs_str)
  return vim.api.nvim_replace_termcodes(rhs_str, true, true, true)
end

return M
