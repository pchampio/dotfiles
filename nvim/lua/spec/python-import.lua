local M = {
  'kiyoon/python-import.nvim',
  ft = { 'python' },
  build = 'python3 -m pipx install . --force',
  keys = {
    {
      '<leader>i',
      function()
        require('python_import.api').add_import_current_word_and_notify()
      end,
      mode = { 'i', 'n' },
      silent = true,
      desc = 'Add python import',
      ft = 'python',
    },
    {
      '<leader>i',
      function()
        require('python_import.api').add_import_current_selection_and_notify()
      end,
      mode = 'x',
      silent = true,
      desc = 'Add python import',
      ft = 'python',
    },
  },
  opts = {
    extend_lookup_table = {
      ---@type string[]
      import = {
        'tqdm',
      },

      ---@type table<string, string>
      import_as = {
        np = 'numpy',
        pd = 'pandas',
      },

      ---@type table<string, string>
      import_from = {
        tqdm = 'tqdm',
      },
    },
  },
}

return M
