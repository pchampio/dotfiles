local M = {
  'dmtrKovalenko/fff.nvim', -- working version: 7cdc71d5a1123a6121ec83cc63949e9916b95cb7
  enabled = true,
  -- build = 'cargo build --release',
  build = 'mkdir -p target/release; wget https://github.com/pchampio/pchampio.github.io/releases/download/1/release.zip -P target/release; unzip target/release/release.zip -d target/release; chmod 777 target/release/*',
  opts = { -- (optional)
    debug = {
      enabled = false, -- we expect your collaboration at least during the beta
      show_scores = false, -- to help us optimize the scoring system, feel free to share your scores!
    },
  },
  -- No need to lazy-load with lazy.nvim.
  -- This plugin initializes itself lazily.
  lazy = false,
}

return M
