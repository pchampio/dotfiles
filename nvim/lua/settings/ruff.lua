---@type vim.lsp.Config
return {
  on_attach = function (client, _)
    -- Disable hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
  end,
  init_options = {
    settings = {
      showSyntaxErrors = true,
      organizeImports = true,
      codeAction = {
        fixViolation = {
          enable = true
        }
      }
    }
  }
}
