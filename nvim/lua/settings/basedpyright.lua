-- Find venv folder in current dir or 1 level deeper (venv/ or proj/venv)
local function find_venv(start_path) -- Finds the venv folder required for LSP
  -- Check current directory (if venv folder is at root)
  local venv_path = start_path .. '/venv'
  if vim.fn.isdirectory(venv_path) == 1 then
    return venv_path
  end
  -- Check one level deeper (e.g if venv is in proj/venv)
  local handle = vim.loop.fs_scandir(start_path)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if type == 'directory' then
        venv_path = start_path .. '/' .. name .. '/venv'
        if vim.fn.isdirectory(venv_path) == 1 then
          return venv_path
        end
      end
    end
  end

  return nil
end
local lsp_restarted = false

local root_dir_basedpyright = function(bufnr, cb)
  local root = vim.fs.root(bufnr, {
    'pyproject.toml',
    'pyrightconfig.json',
    '.git',
  }) or vim.fn.expand '%:p:h'
  cb(root)
end

---@type vim.lsp.Config
local settings = {
  basedpyright = {
    -- use ruff for organizing imports
    disableOrganizeImports = true,
    disableTaggedHints = true,
    typeCheckingMode = 'basic',
    analysis = {
      autoImportCompletions = true,
      autoSearchPaths = true, -- auto serach command paths like 'src'
      diagnosticMode = 'openFilesOnly',
      useLibraryCodeForTypes = true,
      diagnosticSeverityOverrides = {
      --   reportInvalidStubStatement = 'none',
      --   reportUnusedExpression = 'none',
      --   reportUnusedVariable = 'none',
      --   reportInvalidStringEscapeSequence = 'none',
      --   reportPrivateImportUsage = 'none',
      --   reportMissingImports = 'none',
      --   reportUndefinedVariable = 'none',
        reportUnusedImport = 'warning',
        reportUnusedClass = 'warning',
        reportUnusedFunction = 'warning',
      --   reportUnusedParameter = 'none',
      --   reportFunctionMemberAccess = false,
      --   reportArgumentType = false,
      },
    },
  },
}

return {
  filetypes = { 'python' },
  root_dir = root_dir_basedpyright,
  on_attach = function(client, bufnr)
    -- Opt out of semantic token highlighting.
    client.server_capabilities.semanticTokensProvider = nil
  end,
  on_init = function(client)
    if not lsp_restarted then
      local cwd = vim.fn.getcwd()
      local venv_path = find_venv(cwd)
      if venv_path then
        lsp_restarted = true
        settings.python = {
          pythonPath = venv_path .. '/bin/python',
          venvPath = vim.fn.fnamemodify(venv_path, ':h'),
          venv = vim.fn.fnamemodify(venv_path, ':t'),
        }
        vim.schedule(function()
          vim.notify('venv: ' .. venv_path)
          vim.lsp.stop_client(client.id, true)
          vim.lsp.start(client.config)
        end)
      end
    end
    return true
  end,

  settings = settings,
}
