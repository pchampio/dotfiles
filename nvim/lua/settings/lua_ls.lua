---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true)
      },
      -- https://github.com/LuaLS/lua-language-server/wiki/Tips#inlay-hints
      hint = {
        enable = true,
      },
    },
  },
}
