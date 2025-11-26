---@module 'lazy'
---@type LazySpec
return {{
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    win_options = {
      signcolumn = "yes:2",
      statuscolumn = "",
    },
    columns = {
      "icon",
      "size",
      "mtime",
    },
    use_default_keymaps = false,
    keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["<C-i>"] = { "actions.preview", opts = { horizontal = true } },
        ["<C-s>"] = { "actions.preview", opts = { vertical = true } },
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["q"] = { "actions.close", mode = "n" },
        ["<Esc>"] = { "actions.close", mode = "n" },
        ["<C-r>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
    },
  },
  keys = { { '-', '<CMD>Oil<CR>' } },
  -- Optional dependencies
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
  -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
  lazy = false,
  },
  {
    -- I recommend not installing this a dependency of oil as it isn't required
    -- until you open an oil buffer
    "FerretDetective/oil-git-signs.nvim",
    ft = "oil",
    ---@module "oil_git_signs"
    ---@type oil_git_signs.Config
        opts = {
        skip_confirm_for_simple_git_operations = true,
        keymaps = {
            {
                { "n", "v" },
                "<leader>ha",
                function()
                    require("oil-git-signs").stage_selected()
                end,
                { desc = "Stage selected entries" },
            },
            {
                { "n", "v" },
                "<leader>hu",
                function()
                    require("oil-git-signs").unstage_selected()
                end,
                { desc = "Unstage selected entries" },
            },
        },
    },
  },
}
