-- Pull in the wezterm API
local wezterm = require("wezterm")
local os = require("os")

HOME = os.getenv("HOME")

local act = wezterm.action
local config = wezterm.config_builder()


-- Plugins
local bc = require("based_copymode")
local tmux = require("tmux")
local toggle_terminal = require("toggle_terminal")
local auto_complete = require("auto_complete")

-- == Config plugins/personal functions ==
wezterm.on("user-var-changed", function(window, pane, name, value)
  -- play audio on host once downloaded with tssh
  if name == "wez_notif" then
    window:toast_notification('wezterm', value, nil, 1000)
  end
  if name == "wez_audio" then
    local cmd_context = wezterm.json_parse(value)
      toggle_terminal.toggle_terminal(window, pane)
      toggle_terminal.send_command_to_tab(window,  "wait-and-play " .. cmd_context.file .. " " .. cmd_context.flag .. "")
  end
end)

-- RBW auto-complete/bitwarden password manager in wezterm
auto_complete.apply_config({
  shell_path = HOME .. '/.local/bin/zsh',
  log_debug = true,

  -- Password patterns mapped to rbw commands
  password_patterns = {
    ["drakirus.*prr.re.*Authentication code:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'totp'",
    ["drakirus.*gateway.*password:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab prr password'",
    ["drakirus.*server.*password for drakirus"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab prr password'",
    ["zephylac.*zep.*server.*password:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab zep password'",
    ["root@192.168.1.110.*password"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7",
    ["admin@192.168.1.55"] = "rbw get 8136bc67-e189-487e-b7ec-ae9083b79986",
  },

  -- Fallback InputSelector options
  fallback_passwords_prompt = {
    { id = "rbw get 2ac8a334-7607-42b5-9198-5c31c371599e", label = "PP" },
    { id = "rbw get 242d4b24-ea36-4eb9-bea3-c4a4d4f8da63 --field gh cli", label = "GH Token" },
    { id = "rbw get a25b73d3-942c-4c8a-b424-b85c59f433fc --field token", label = "Gitea Token" },
    { id = "rbw get 6ed8aac4-1443-43ed-b42e-c484ca281610 --field rbw_config_2", label = "CONF: RBW 1" },
    { id = "rbw get 6ed8aac4-1443-43ed-b42e-c484ca281610 --field rbw_config_3", label = "CONF: RBW 2" },
    { id = "rbw get 6ed8aac4-1443-43ed-b42e-c484ca281610 --field rbw_config_4", label = "CONF: RBW 3" },
    { id = "rbw get 6ed8aac4-1443-43ed-b42e-c484ca281610 --field 'clone dotfiles'", label = "CONF: clone dotfiles" },
  },

  -- Vault management functions
  is_locked = function()
    local success = wezterm.run_child_process({ HOME .. "/.local/bin/rbw", "unlocked" })
    return not success
  end,

  unlock = function(window)
    local old = toggle_terminal.opts.size.Cells
    toggle_terminal.opts.size.Cells = 2
    toggle_terminal.toggle_terminal(window, window:active_pane())
    toggle_terminal.send_command_to_tab(window,  HOME .. "/.local/bin/rbw unlock; exit" )

    -- Wait until unlocked
    auto_complete.run_cmd_until_true("rbw unlocked")
    toggle_terminal.opts.size.Cells = old
  end,
})

config.max_fps = 120
-- config.front_end = "WebGpu" -- Default is 'OpenGL' better characters IMO
config.enable_wayland = true

-- config.tiling_desktop_environments = {
--   'Wayland' -- cosmic popos TODO: doesn't work
-- }

-- config.window_decorations = "NONE"

config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" } -- Disable ligatures.
config.warn_about_missing_glyphs = false
config.selection_word_boundary = " \t\n{}[]()\"'`,;:|│├┤"

local openUrl = act.QuickSelectArgs({
  label = "open url",
  patterns = { "https?://\\S+" },
  action = wezterm.action_callback(function(window, pane)
    local url = window:get_selection_text_for_pane(pane)
    wezterm.open_with(url)
  end),
})


config.enable_tab_bar = false
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.disable_default_key_bindings = true
config.keys = {
  -- CTRL-SHIFT-i activates the debug overlay
  { key = "i", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
  -- zooms
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "h", mods = "CTRL", action = tmux.move_or_send("Left", "h") },
  { key = "j", mods = "CTRL", action = tmux.move_or_send("Down", "j") },
  { key = "k", mods = "CTRL", action = tmux.move_or_send("Up", "k") },
  { key = "l", mods = "CTRL", action = tmux.move_or_send("Right", "l") },
  -- clipboard
  { key = "C", mods = "SHIFT|CTRL", action = act.CopyTo("ClipboardAndPrimarySelection") },
  {
    key = "V",
    mods = "SHIFT|CTRL",
    action = wezterm.action_callback(function(window, pane)
      local success, stdout, stderr = wezterm.run_child_process({ "wl-paste", "--no-newline" })
      if success then
        pane:paste(stdout)
      else
        wezterm.log_error("wl-paste failed with\n" .. stderr .. stdout)
      end
    end),
  }, -- Or Clipboard depending on the setting
  -- OpenUrl
  { key = "x", mods = "SHIFT|CTRL", action = openUrl },
  -- Quit
  { key = "q", mods = "CMD",        action = act.QuitApplication },

  {
    key = "L",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(auto_complete.auto_complete),
  },
}

config.bypass_mouse_reporting_modifiers = "SHIFT"
config.quick_select_remove_styling = true
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    action = bc.single_streak_click,
  },
  {
    event = { Up = { streak = 2, button = "Left" } },
    action = bc.double_streak_click,
  },
}


-- Define the colors just once
local solarized_colors = {
  -- https://ethanschoonover.com/solarized/#the-values
  ansi = {
    "lab(20% -12 -12)",
    "lab(50%  65  45)",
    "lab(60% -20  65)",
    "lab(60%  10  65)",
    "lab(55% -10 -45)",
    "lab(50%  65 -05)",
    "lab(60% -35 -05)",
    "lab(92% -00  10)",
  },
  brights = {
    "lab(15% -12 -12)",
    "lab(50%  50  55)",
    "lab(45% -07 -07)",
    "lab(50% -07 -07)",
    "lab(60% -06 -03)",
    "lab(50%  15 -45)",
    "lab(65% -05 -02)",
    "lab(97%  00  10)",
  },
}

config.color_schemes = {
  -- https://ethanschoonover.com/solarized/#usage-development
  -- No selection_fg since the solarized selection_bg is designed to work without it
  ["Canonical Solarized Light"] = {
    foreground = solarized_colors.brights[4],
    background = "#fbf3db",
    cursor_bg = solarized_colors.brights[3],
    cursor_border = solarized_colors.brights[3],
    cursor_fg = solarized_colors.ansi[8],
    selection_bg = solarized_colors.ansi[8],
    selection_fg = "none",
    split = solarized_colors.brights[3],
  },
  ["Canonical Solarized Dark"] = {
    foreground = solarized_colors.brights[5],
    background = solarized_colors.brights[1],
    cursor_bg = solarized_colors.brights[7],
    cursor_border = solarized_colors.brights[7],
    cursor_fg = solarized_colors.ansi[1],
    selection_bg = solarized_colors.ansi[1],
    selection_fg = "none",
    split = solarized_colors.brights[7],
  },
}

-- Assign the colors
config.colors = solarized_colors
-- Solarized is incompatible with this option
config.bold_brightens_ansi_colors = "No"

config.color_scheme = "Canonical Solarized Light"

-- the foreground color of selected text
config.colors.selection_fg = "#0f0f0e"
-- the background color of selected text
config.colors.selection_bg = "#aaa46d"


config.hyperlink_rules = {
  -- Linkify things that look like URLs
  -- This is actually the default if you don't specify any hyperlink_rules
  {
    regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b",
    format = "$0",
  },
  -- match the URL with a PORT
  -- such 'http://localhost:3000/index.html'
  {
    regex = "\\b\\w+://(?:[\\w.-]+):\\d+\\S*\\b",
    format = "$0",
  },
  -- file:// URI
  {
    regex = "\\bfile://\\S*\\b",
    format = "$0",
  },
}

toggle_terminal.apply_to_config(config)

-- and finally, return the configuration to wezterm
return config

-- vim: set tabstop=2 shiftwidth=2 expandtab:
