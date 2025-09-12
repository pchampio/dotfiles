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
    'pyright',
    'harper_ls',
  },
}

function M.utils.isBufSizeBig(buf)
  local ok, size = pcall(vim.fn.getfsize, vim.api.nvim_buf_get_name(buf))
  return ok and size > M.constants.big_file_size
end

function M.utils.rhs(rhs_str)
  return vim.api.nvim_replace_termcodes(rhs_str, true, true, true)
end

return M
