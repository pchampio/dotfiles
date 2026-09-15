local wezterm = require('wezterm')
local toggle_terminal = require('toggle_terminal')
local M = {}

function M.apply_to_config(config, opts)
  opts = opts or {}
  table.insert(config.keys, {
    key = opts.key or 'B',
    mods = opts.mods or 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      toggle_terminal.toggle_command(window, pane, 'voice', {
        domain = { DomainName = 'local' },
        cwd = wezterm.home_dir,
        size = opts.size or 2,
        args = {
          '/usr/bin/python3', wezterm.home_dir .. '/dotfiles/config/wezterm/voice/voice.py',
          'record', '--pane-id', tostring(pane:pane_id()),
          '--host', opts.host or 'ampere', '--lang', opts.lang or 'en-US',
        },
      })
    end),
  })
end

return M
