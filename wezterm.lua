-- Pull in the wezterm API
local wezterm = require("wezterm")
local io = require("io")
local os = require("os")

HOME = os.getenv("HOME")

local act = wezterm.action
local config = wezterm.config_builder()

config.max_fps = 120
config.front_end = "WebGpu"

config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"
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

wezterm.on("user-var-changed", function(window, pane, name, value)
  if name == "wez_audio" then
    local cmd_context = wezterm.json_parse(value)
    -- Open a new tab and play the audio
    window:perform_action(
      wezterm.action.SpawnCommandInNewTab({
        label = "Remote Audio Player",
        args = { HOME .. "/dotfiles/bin/wait-and-play", cmd_context.file, cmd_context.flag },
      }),
      pane
    )
  end
end)

-- For example, changing the color scheme:
config.automatically_reload_config = true

config.enable_tab_bar = false

config.warn_about_missing_glyphs = false

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
  { key = "+", mods = "CTRL",       action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL",       action = act.DecreaseFontSize },
  { key = "0", mods = "CTRL",       action = act.ResetFontSize },
  { key = "=", mods = "CTRL",       action = act.IncreaseFontSize },
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
    action = wezterm.action_callback(function(window, pane)
      local cursor = pane:get_cursor_position()
      local text = wezterm.split_by_newlines(pane:get_logical_lines_as_text())

      -- for i, line in ipairs(text) do
      --   wezterm.log_info(line)
      -- end

      wezterm.log_info("Cursor")
      wezterm.log_info(cursor.y)
      wezterm.log_info(pane:get_cursor_position().y - pane:get_dimensions().physical_top)

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

      local success_unlock, _, _ =
          wezterm.run_child_process(wezterm.shell_split(HOME .. "/dotfiles/bin/rbw_bin/rbw" .. " unlocked"))

      if not success_unlock then
        window:perform_action(
          act.SpawnCommandInNewTab({
            label = "Unlock vault",
            args = { HOME .. "/dotfiles/bin/rbw", "unlock" },
          }),
          window:active_pane()
        )

        -- Wait
        wezterm.run_child_process(
          wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "until rbw unlocked; do sleep 1; done"')
        )
      end

      local password_patterns = {
        ["drakirus.*prr.re.*Authentication code:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'totp'",
        ["drakirus.*gateway.*password:"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab prr password'",
        ["drakirus.*server.*password for drakirus"] =
        "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab prr password'",
        ["zephylac.*zep.*server.*password:"] =
        "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7 --field 'Homelab zep password'",
        ["root@192.168.1.110.*password"] = "rbw get 32d66a6f-ef01-4835-8ad1-aae19fa717a7",
        ["admin@192.168.1.55"] = "rbw get 8136bc67-e189-487e-b7ec-ae9083b79986",
      }

      for pattern, cmd_get_pwd in pairs(password_patterns) do
        wezterm.log_info(text_at_cursor)
        wezterm.log_info(pattern)
        wezterm.log_info(string.find(text_at_cursor, pattern))
        if string.find(text_at_cursor, pattern) then
          wezterm.log_info("FOUND")
          local success, password, stderr = wezterm.run_child_process(
            wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "' .. cmd_get_pwd .. '"')
          )
          wezterm.log_info(success)
          wezterm.log_info(password)
          wezterm.log_info(stderr)
          password = password:match(".*$~[^%s]+%s(.*)") -- remove interactive colored string and PS1 prompt
          wezterm.log_info(password)
          if not (password == nil or password == '') then
            window:perform_action(
              wezterm.action.Multiple({
                wezterm.action.SendString(password),
                wezterm.action.SendKey({ key = "Enter" }),
              }),
              window:active_pane()
            )
            return
          end
          return
        end
      end

      for pattern, cmd_get_pwd in pairs(password_patterns) do
        if string.find(pane:get_logical_lines_as_text(), pattern) then
          wezterm.log_info("FOUND")
          local success, password, stderr = wezterm.run_child_process(
            wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "' .. cmd_get_pwd .. '"')
          )
          wezterm.log_info(password)
          password = password:match(".*$~[^%s]+%s(.*)") -- remove interactive colored string and PS1 prompt
          wezterm.log_info(success)
          wezterm.log_info(password)
          wezterm.log_info(stderr)
          if not (password == nil or password == '') then
            window:perform_action(
              wezterm.action.Multiple({
                wezterm.action.SendString(password),
                wezterm.action.SendKey({ key = "Enter" }),
              }),
              window:active_pane()
            )
            return
          end
        end
      end

      local passwords = {
        { id = "rbw get 2ac8a334-7607-42b5-9198-5c31c371599e",                label = "PP" },
        { id = "rbw get 242d4b24-ea36-4eb9-bea3-c4a4d4f8da63 --field gh cli", label = "GH Token" },
        { id = "rbw get a25b73d3-942c-4c8a-b424-b85c59f433fc --field token",  label = "Gitea Token" },
      }

      window:perform_action(
        act.InputSelector({
          action = wezterm.action_callback(function(inner_window, inner_pane, cmd, label)
            if not cmd and not label then
              wezterm.log_info("cancelled")
            else
              local success, password, stderr = wezterm.run_child_process(
                wezterm.shell_split(HOME .. '/dotfiles/bin/zsh -ic "' .. cmd .. '"')
              )
              wezterm.log_info(password)
              password = password:match(".*$~[^%s]+%s(.*)") -- remove interactive colored string and PS1 prompt
              wezterm.log_info(success)
              wezterm.log_info(stderr)
              window:perform_action(
                wezterm.action.Multiple({
                  wezterm.action.SendString(password),
                  wezterm.action.SendKey({ key = "Enter" }),
                }),
                window:active_pane()
              )
            end
          end),
          title = "Choose Password",
          choices = passwords,
          fuzzy = true,
          fuzzy_description = "Fuzzy find a password to input: ",
        }),
        pane
      )
    end),
  },
}


wezterm.on("clear-selection-after-delay", function(window, pane)
  -- run this after a delay
  wezterm.sleep_ms(250)
  window:perform_action(wezterm.action.ClearSelection, pane)
end)

config.bypass_mouse_reporting_modifiers = "SHIFT" -- ANY mapping appears without shift in wezterm when tmux is used
config.quick_select_remove_styling = true         -- make it obvious when we under select mode

-- I hate that wezterm keeps rendering and discard the already selected text while I try to select some text.
-- This pice of code stops wezterm from clearing out the selected text while I'm in thre process of selcting it
-- I activate it by pressing Shit-Click
config.mouse_bindings = {
  -- Custom binding for Shift + Left Click to start selection and log
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "",
    action = act.Multiple({
      wezterm.action.QuickSelectArgs({
        patterns = {
          "jksfldjjkfdsljflflsdkfjlsdjfdsfjlsdjflksdjklf",
        },
      }),
      act.SelectTextAtMouseCursor("Cell"),
    }),
  },
  {
    event = { Down = { streak = 2, button = "Left" } },
    mods = "",
    action = act.Multiple({
      wezterm.action.QuickSelectArgs({
        patterns = {
          "jksfldjjkfdsljflflsdkfjlsdjfdsfjlsdjflksdjklf",
        },
      }),
      act.SelectTextAtMouseCursor("Word"),
      act.CopyTo("ClipboardAndPrimarySelection"),
      wezterm.action.SendKey({ key = "Escape" }), -- escape QuickSelect
      wezterm.action.EmitEvent("clear-selection-after-delay"),
    }),
  },
  {
    event = { Up = { streak = 1, button = "Right" } },
    mods = "",
    action = act.Multiple({
      act.CopyTo("ClipboardAndPrimarySelection"),
      wezterm.action.SendKey({ key = "Escape" }), -- escape QuickSelect
      wezterm.action.EmitEvent("clear-selection-after-delay"),
    }),
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

-- config.window_decorations = "NONE"
config.enable_wayland = true

-- config.tiling_desktop_environments = {
--   'Wayland' -- cosmic popos TODO: doesn't work
-- }


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

-- vim: set tabstop=2 shiftwidth=2 expandtab:
