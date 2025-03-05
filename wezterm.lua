-- Pull in the wezterm API
local wezterm = require 'wezterm'
local io = require 'io'
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

config.max_fps = 120

config.audible_bell = "Disabled"
config.window_close_confirmation = 'NeverPrompt'
-- Disable ligatures.
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.selection_word_boundary = " \t\n{}[]()\"'`,;:|│├┤"

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

config.disable_default_key_bindings = true
config.keys = {
  -- CTRL-SHIFT-i activates the debug overlay
  { key = 'i', mods = 'CTRL|SHIFT', action = act.ShowDebugOverlay },
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

  { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },

  {
    key = 'L',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)


      local workspace = wezterm.mux.get_active_workspace()
      for _, mw in ipairs(wezterm.mux.all_windows()) do
        if mw:get_workspace() == workspace then
          local window = mw:gui_window()
          local pane = window:active_pane()
          local cursor = pane:get_cursor_position()
          local text = wezterm.split_by_newlines(pane:get_logical_lines_as_text())

          -- for i, line in ipairs(text) do
          --   wezterm.log_info(line)
          -- end

          wezterm.log_info("Cursor")
          wezterm.log_info(cursor.y)
          wezterm.log_info(pane:get_cursor_position().y - pane:get_dimensions().physical_top )

          local prev_prev_line = text[cursor.y - 2] or ""
          local prev_line = text[cursor.y - 1] or ""
          local curr_line = text[cursor.y] or ""
          local next_line = text[cursor.y + 1] or ""

          local start_index = math.max(1, cursor.x - 60)

          -- Safely handle each string.sub call
          local prev_prev_text = string.sub(prev_prev_line, start_index) or ""
          local prev_text = string.sub(prev_line, start_index) or ""
          local curr_text = string.sub(curr_line, start_index) or pane:get_logical_lines_as_text()
          local next_text = string.sub(next_line, start_index) or ""

          -- Concatenate the strings
          local text_at_cursor = prev_prev_text .. prev_text .. curr_text .. next_text

          wezterm.log_info("text:")
          wezterm.log_info(text_at_cursor)

          local password_patterns = {
            ["drakirus.*prr.re.*Authentication code:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'totp'",
            ["drakirus.*gateway.*password:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab prr password'",
            ["drakirus.*server.*password for drakirus"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab prr password'",
            ["password for drakirus"] = "rbw get 2ac8a334-7607-42b5-9198-5c31c371599e",
            ["zephylac.*zep.*server.*password:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab zep password'",
            ["root@192.168.1.110.*password"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7",
            ["Master Password:"] = "rbw get 2ac8a334-7607-42b5-9198-5c31c371599e",
          }

              -- window:perform_action(wezterm.action.Multiple {
              --   wezterm.action.SendString("test"),
              --   wezterm.action.SendKey { key = 'Enter' },
              -- }, window:active_pane())

          for pattern, cmd_get_pwd in pairs(password_patterns) do
            wezterm.log_info(text_at_cursor)
            wezterm.log_info(pattern)
            wezterm.log_info(string.find(text_at_cursor, pattern))
            if string.find(text_at_cursor, pattern) then
              local success, password, stderr = wezterm.run_child_process(wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "'.. cmd_get_pwd .. '"'))
              -- wezterm.log_info(success)
              -- wezterm.log_info(stderr)
              window:perform_action(wezterm.action.Multiple {
                wezterm.action.SendString(password),
                wezterm.action.SendKey { key = 'Enter' },
              }, window:active_pane())
              return
            end
          end

          for pattern, cmd_get_pwd in pairs(password_patterns) do
            if string.find(pane:get_logical_lines_as_text(), pattern) then
              local success, password, stderr = wezterm.run_child_process(wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "'.. cmd_get_pwd .. '"'))
              -- wezterm.log_info(success)
              -- wezterm.log_info(stderr)
              window:perform_action(wezterm.action.Multiple {
                wezterm.action.SendString(password),
                wezterm.action.SendKey { key = 'Enter' },
              }, window:active_pane())
              return
            end
          end

        end
      end

      local passwords = {
        { id = "rbw get 2ac8a334-7607-42b5-9198-5c31c371599e", label = 'PP' },
        { id = "rbw get 242d4b24-ea36-4eb9-bea3-c4a4d4f8da63 --field gh cli", label = 'GH Token' },
        { id = "rbw get a25b73d3-942c-4c8a-b424-b85c59f433fc --field token", label = 'Gitea Token' },
      }

      window:perform_action(
        act.InputSelector {
          action = wezterm.action_callback(
            function(inner_window, inner_pane, cmd, label)
              if not cmd and not label then
                wezterm.log_info 'cancelled'
              else
                local success, password, stderr = wezterm.run_child_process(wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "'.. cmd .. '"'))
                -- wezterm.log_info(success)
                -- wezterm.log_info(stderr)
                window:perform_action(wezterm.action.Multiple {
                  wezterm.action.SendString(password),
                  wezterm.action.SendKey { key = 'Enter' },
                }, window:active_pane())
              end
            end
          ),
          title = 'Choose Password',
          choices = passwords,
          fuzzy = true,
          fuzzy_description = 'Fuzzy find a password to input: ',
        },
        pane
      )

    end),
  },

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


config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.ActivateCopyMode,
	},
}


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
-- and finally, return the configuration to wezterm
return config
