local M = {}
local wezterm = require("wezterm")
local act = wezterm.action

-- based copy selection Helper
-- (quickselect under the hood)
-- Enter with: Shift click enter under tmux
--             Click enter under normal wezterm
-- Selected text will be copied, double click will copy word
--   Why: When selecting text that is \r re-rendered, wezterm will Clear the selection, driving me mad.
--   With those functions: First Click enters based copy mode.
--                         Click and hold (normal text selection), then release -> the text is copied.
--                         Double click copy Word
--
-- CONFIG:
-- config.mouse_bindings = {
--   {
--     event = { Up = { streak = 1, button = "Left" } },
--     action = bc.single_streak_click,
--   },
--   {
--     event = { Up = { streak = 2, button = "Left" } },
--     action = bc.double_streak_click,
--   },
-- }
-- OPTIONAL:
-- config.bypass_mouse_reporting_modifiers = "SHIFT" to make it work under tmux
-- config.quick_select_remove_styling = true for the easier focus


local bc_clicked = false
wezterm.on("BC_clear-selection-after-delay", function(window, pane)
  window:perform_action(act.SendKey({ key = "Escape" }), pane)
  bc_clicked = false
  wezterm.sleep_ms(250)
  window:perform_action(act.ClearSelection, pane)
end)

wezterm.on("BC_toggle-clicked", function(window, pane)
  bc_clicked = not bc_clicked
  local text = window:get_selection_text_for_pane(pane)
  if text and text ~= "" then
    window:perform_action(
      act.Multiple({act.CopyTo("ClipboardAndPrimarySelection"), wezterm.action.EmitEvent("BC_clear-selection-after-delay")})
    , pane)
  end
end)
wezterm.on("BC_enter-quickselect", function(window, pane)
  if not bc_clicked then
    -- a dummy pattern to force QuickSelect mode activation (Good on constantly redrawn terminal)
    window:perform_action(act.QuickSelectArgs({
      patterns = { "jksfldjjkfdsljflflsdkfjlsdjfdsfjlsdjflksdjklf" },
    }), pane)
  end
end)

M.single_streak_click = act.Multiple({
  wezterm.action.EmitEvent("BC_enter-quickselect"),
  wezterm.action.EmitEvent("BC_toggle-clicked"),
})

M.double_streak_click = act.Multiple({
      act.SelectTextAtMouseCursor("Word"),            -- select word
      act.CopyTo("ClipboardAndPrimarySelection"),     -- copy immediately
      wezterm.action.EmitEvent("BC_clear-selection-after-delay"),
})

return M
