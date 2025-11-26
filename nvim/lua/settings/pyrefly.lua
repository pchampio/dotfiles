local root_dir_pyrefly = function(bufnr, cb)
  local root = vim.fs.root(bufnr, {
    'pyproject.toml',
    'pyrefly.roml',
    '.git',
  }) or vim.fn.expand '%:p:h'
  cb(root)
end

return {
  cmd = { 'pyrefly', 'lsp' },
  filetypes = { 'python' },
  root_dir = root_dir_pyrefly,
  on_attach = function(client, _)
    client.server_capabilities.codeActionProvider     = false -- basedpyright has more kinds
    client.server_capabilities.documentSymbolProvider = false
    client.server_capabilities.hoverProvider          = false
    client.server_capabilities.inlayHintProvider      = false
    client.server_capabilities.referenceProvider      = false
    client.server_capabilities.signatureHelpProvider  = false
  end,
  settings = {},
}
