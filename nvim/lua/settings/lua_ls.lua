return {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
      -- https://github.com/LuaLS/lua-language-server/wiki/Tips#inlay-hints
      hint = {
        enable = true,
      },
    },
  },
}
