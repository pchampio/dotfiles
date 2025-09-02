local M = {
  'dmtrKovalenko/fff.nvim',
  enabled = false,
  build = 'cargo build --release',
  -- build = 'mkdir -p target/release; wget https://file.prr.re/invit/libfff_nvim.so -P target/release; chmod 777 target/release/libfff_nvim.so ',
  opts = { -- (optional)
    debug = {
      enabled = true, -- we expect your collaboration at least during the beta
      show_scores = true, -- to help us optimize the scoring system, feel free to share your scores!
    },
  },
  -- No need to lazy-load with lazy.nvim.
  -- This plugin initializes itself lazily.
  lazy = false,
}

return M
