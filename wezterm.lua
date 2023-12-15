-- Pull in the wezterm API
local wezterm = require 'wezterm'
local os = require 'os'

HOME = os.getenv("HOME")

wezterm.GLOBALS = wezterm.GLOBALS or {}
wezterm.GLOBALS.seen_windows = wezterm.GLOBALS.seen_windows or {}

wezterm.on("window-config-reloaded", function(window)
    local id = window:window_id()

    local is_new_window = not wezterm.GLOBALS.seen_windows[id]
    wezterm.GLOBALS.seen_windows[id] = true

    if is_new_window then
      window:maximize()
      window:focus()
    end
end)

wezterm.on('gui-startup', function()
  local tab, pane, window = wezterm.mux.spawn_window({})
  window:gui_window():maximize()
  window:gui_window():focus()
end)

local act = wezterm.action
local config = wezterm.config_builder()

config.audible_bell = "Disabled"
config.window_close_confirmation = 'NeverPrompt'
-- Disable ligatures.
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config. selection_word_boundary = " \t\n{}[]()\"'`,;:|│"

local openUrl = act.QuickSelectArgs({
  label = "open url",
  patterns = { "https?://\\S+" },
  action = wezterm.action_callback(function(window, pane)
    local url = window:get_selection_text_for_pane(pane)
    wezterm.open_with(url)
  end),
})

-- For example, changing the color scheme:
config.automatically_reload_config = true

config.enable_tab_bar = false
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
local to = function()
  return act.Multiple {
    act.SpawnCommandInNewTab({
      label = 'Get Totp',
      args = { HOME .. "/.local/bin/zsh", "-ic", "bw_totp_1" },
    }),
    -- act.PasteFrom("Clipboard")
    wezterm.action_callback(function(win, pane)
      local clipboard = ""
      while not clipboard:match "^BW@:" do
        local success, stdout, stderr = wezterm.run_child_process { "xclip", "-o", "-selection", "clipboard" }
        clipboard = stdout
        wezterm.sleep_ms(100)
      end
      pane:send_paste(clipboard:sub(5))
    end)
  }
end

config.disable_default_key_bindings = true
config.keys = {
  -- CTRL-SHIFT-i activates the debug overlay
  { key = 'I', mods = 'CTRL', action = act.ShowDebugOverlay },
  -- Bitwarden like extension
  { key = "l", mods = "CTRL|SHIFT",  action = to()},
  -- zooms
  { key = "+", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  -- clipboard
  { key = "C", mods = "SHIFT|CTRL", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "SHIFT|CTRL", action = act.PasteFrom("Clipboard") },
  -- OpenUrl
  { key = "x", mods = "SHIFT|CTRL", action = openUrl },
  -- Quit
  { key = "q", mods = "CMD", action = act.QuitApplication },
}
config.mouse_bindings = {
  { event = { Drag = { streak = 1, button = "Left" } }, mods = "SHIFT", action = act({ ExtendSelectionToMouseCursor = "Cell" }) },
  { event = { Drag = { streak = 2, button = "Left" } }, mods = "SHIFT", action = act({ ExtendSelectionToMouseCursor = "Word" }) },
  { event = { Drag = { streak = 3, button = "Left" } }, mods = "SHIFT", action = act({ ExtendSelectionToMouseCursor = "Line" }) },
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
    "lab(92% -00  10)"
  },
  brights = {
    "lab(15% -12 -12)",
    "lab(50%  50  55)",
    "lab(45% -07 -07)",
    "lab(50% -07 -07)",
    "lab(60% -06 -03)",
    "lab(50%  15 -45)",
    "lab(65% -05 -02)",
    "lab(97%  00  10)"
  }
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
    split = solarized_colors.brights[3]
  },
  ["Canonical Solarized Dark"] = {
    foreground = solarized_colors.brights[5],
    background = solarized_colors.brights[1],
    cursor_bg = solarized_colors.brights[7],
    cursor_border = solarized_colors.brights[7],
    cursor_fg = solarized_colors.ansi[1],
    selection_bg = solarized_colors.ansi[1],
    selection_fg = "none",
    split = solarized_colors.brights[7]
  }
}

-- Assign the colors
config.colors = solarized_colors
-- Solarized is incompatible with this option
config.bold_brightens_ansi_colors = "No"

config.color_scheme = 'Canonical Solarized Light'

-- the foreground color of selected text
config.colors.selection_fg = '#0f0f0e'
-- the background color of selected text
config.colors.selection_bg = '#aaa46d'

config.window_decorations = "TITLE | RESIZE"
config.adjust_window_size_when_changing_font_size = true
config.enable_wayland = true

-- table.insert(config.hyperlink_rules, {
-- 	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
-- 	format = "https://github.com/$1/$3",
-- })

-- and finally, return the configuration to wezterm
return config
