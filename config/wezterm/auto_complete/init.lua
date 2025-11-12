-- Password manager inside wezterm
local wezterm = require("wezterm")
local M = {}

-- CONFIGURATION
M.config = {
  shell_path =  '/bin/zsh', -- shell bin to run cmd in shell needed for until
  log_debug = true,

  -- Password patterns mapped to rbw commands
  password_patterns = {
    [".*Authentication code:"] = "pass get id",
  },

  -- Fallback InputSelector options
  fallback_passwords_prompt = {
    { id = "pass get id", label = "Get password named XX" },
  },

  -- Vault management functions
  is_locked = function()
    local success = wezterm.run_child_process({ "rbw", "unlocked" })
    return not success
  end,

  unlock = function(window)
    window:perform_action(
      wezterm.action.SpawnCommandInNewTab({
        label = "Unlock vault",
        args = { "rbw", "unlock" },
      }),
      window:active_pane()
    )
    -- Wait until unlocked
    M.run_cmd_until_true("rbw unlocked")
  end,
}

-- Apply new configuration
function M.apply_config(new_config)
  if type(new_config) ~= "table" then
    M.log_info("apply_config: argument must be a table")
    return
  end

  for k, v in pairs(new_config) do
    M.config[k] = v
  end

  M.log_info("Configuration applied:", new_config)
end

-- Custom logging
function M.log_info(...)
  if M.config.log_debug then
    local args = { ... }
    local output = {}
    for i, v in ipairs(args) do
      table.insert(output, tostring(v))
    end
    wezterm.log_info("[AutoComplete] " .. table.concat(output, " "))
  end
end

-- Safely get substring
local function safe_sub(str, start_index)
  if str and #str >= start_index then
    return string.sub(str, start_index)
  else
    return ""
  end
end

function M.run_cmd_until_true(cmd)
  M.run_cmd(cmd, true)
end

-- Run command via shell, optionally retrying until success
function M.run_cmd(cmd, wait_until_success)
  wait_until_success = wait_until_success or false
  if wait_until_success then
    -- Wrap the command in a loop that retries until success
    cmd = 'until ' .. cmd .. '; do sleep 1; done'
  end
  local success, stdout, stderr = wezterm.run_child_process({ M.config.shell_path, "-ic", cmd })
  stdout = stdout and stdout:match(".*$~[^%s]+%s(.*)") or stdout
  return success, stdout, stderr
end

function M.auto_complete(window, pane)
  local cursor = pane:get_cursor_position()
  local text_lines = wezterm.split_by_newlines(pane:get_logical_lines_as_text())
  local start_index = math.max(1, cursor.x - 60)
  local text_at_cursor =
      safe_sub(text_lines[cursor.y - 2] or "", start_index) ..
      safe_sub(text_lines[cursor.y - 1] or "", start_index) ..
      safe_sub(text_lines[cursor.y] or "", start_index) ..
      safe_sub(text_lines[cursor.y + 1] or "", start_index)

  M.log_info("Text at cursor:", text_at_cursor)

  -- Ensure vault is unlocked
  if M.config.is_locked() then
    M.config.unlock(window)
  end

  -- === LOOP 1: Check text around cursor ===
  for pattern, cmd_get_pwd in pairs(M.config.password_patterns) do
    M.log_info("Checking pattern:", pattern)
    if string.find(text_at_cursor, pattern) then
      M.log_info("FOUND pattern near cursor:", pattern)
      local success, password, stderr = M.run_cmd(cmd_get_pwd)
      M.log_info("success:", success, "password:", password, "stderr:", stderr)
      if password and #password > 0 then
        window:perform_action(
          wezterm.action.Multiple({
            wezterm.action.SendString(password),
            -- wezterm.action.SendKey({ key = "Enter" }),
          }),
          window:active_pane()
        )
        return
      end
      return
    end
  end

  -- === LOOP 2: Check visible pane text ===
  local pane_text = pane:get_logical_lines_as_text(pane:get_dimensions().scrollback_rows)
  for pattern, cmd_get_pwd in pairs(M.config.password_patterns) do
    M.log_info("Checking pattern:", pattern)
    M.log_info("In pane text:", pane_text)
    if string.find(pane_text, pattern) then
      M.log_info("FOUND pattern in pane:", pattern)
      local success, password, stderr = M.run_cmd(cmd_get_pwd)
      M.log_info("success:", success, "password:", password, "stderr:", stderr)
      if password and #password > 0 then
        window:perform_action(
          wezterm.action.Multiple({
            wezterm.action.SendString(password),
            -- wezterm.action.SendKey({ key = "Enter" }),
          }),
          window:active_pane()
        )
        return
      end
    end
  end

  -- === Fallback InputSelector ===
  window:perform_action(
    wezterm.action.InputSelector({
      title = "Choose Password",
      choices = M.config.fallback_passwords_prompt,
      fuzzy = true,
      fuzzy_description = "Fuzzy find a password to input: ",
      action = wezterm.action_callback(function(inner_window, inner_pane, cmd, label)
        if cmd and label then
          local success, password, stderr = M.run_cmd(cmd)
          M.log_info("success:", success, "password:", password, "stderr:", stderr)
          inner_window:perform_action(
            wezterm.action.Multiple({
              wezterm.action.SendString(password),
              -- wezterm.action.SendKey({ key = "Enter" }),
            }),
            inner_pane
          )
        end
      end),
    }),
    pane
  )
end

return M
