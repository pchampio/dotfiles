local M = {}

local wezterm = require("wezterm")
local act = wezterm.action

local function last_line_matches(pane, pattern)
  local lines = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
  if not lines or #lines == 0 then
    return false
  end
  return lines:find(pattern) ~= nil
end

local function is_inside_tmux(pane)
  return last_line_matches(pane, "──────────") -- always in my tmux config (bottom line)
end


-- timestamp of last keypress (used for changing tmux/wezterm pane)
local last_fallback_time = 0

-- Tries to move to a pane in the given direction
-- If no pane exists, sends the original key+mods to the terminal
local function smart_pane_nav(window, pane, direction, key, mods)
  local current_pane = pane:pane_id()
  window:perform_action(act.ActivatePaneDirection(direction), pane)
  local new_pane = window:active_pane():pane_id()

  if new_pane == current_pane then
    -- No pane in that direction: send original key + modifiers
    window:perform_action(act.SendKey{ key = key, mods = mods }, pane)
  end
end

function M.move_or_send(direction, key)
  return wezterm.action_callback(function(window, pane)
    if is_inside_tmux(pane) then
      -- send Ctrl+key to tmux
      window:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
    else
      smart_pane_nav(window, pane, direction, key, "CTRL")
    end
  end)
end

return M
