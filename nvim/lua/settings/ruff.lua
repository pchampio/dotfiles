vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("ak_lsp_ruff", {}),
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client.name ~= "ruff" then return end

    -- Disable hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
  end,
})

return {
  init_options = {
    settings = {
      args = { "--ignore=E501" },  -- Line too long
      lineLength = 120,
      fixAll = true,
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
