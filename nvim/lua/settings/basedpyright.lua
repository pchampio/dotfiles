-- Use Ruff exclusively for linting, formatting and organizing imports, and disable those capabilities in Pyright
return {
  settings = {
    basedpyright = {
      -- use ruff-lsp for organizing imports
      disableOrganizeImports = true,
      disableTaggedHints = true,
      typeCheckingMode = 'basic',
      -- disable pyright's built-in analysis
      analysis = {
        diagnosticMode = 'openFilesOnly',
        diagnosticSeverityOverrides = {
          reportUnusedExpression = 'none',
          reportUnusedVariable = 'none',
          reportUnusedFunction = false,
          reportInvalidStringEscapeSequence = "none",
          reportUnusedClass = false,
          reportPrivateImportUsage = 'none',
          reportMissingImports = 'none',
          reportUndefinedVariable = 'none',
          reportUnusedImport = 'none',
          reportUnusedParameter = 'none',
          reportFunctionMemberAccess = false,
          reportArgumentType = false,
        },
      },
    },
  },
}
