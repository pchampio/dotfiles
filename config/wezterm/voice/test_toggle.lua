-- Run from the repository root: lua config/wezterm/voice/test_toggle.lua
local panes, focused, splits, last_spawn = {}, nil, 0, nil
local tab = { zoomed = false }
function tab:tab_id() return 1 end
function tab:set_zoomed(value) self.zoomed = value end
local function pane(id)
  local p = {}
  function p:pane_id() return id end
  function p:tab() return tab end
  function p:activate() focused = id end
  function p:split(spawn)
    assert(({ Bottom = true, Top = true, Left = true, Right = true })[spawn.direction],
      'pane:split requires Top/Bottom, not Up/Down')
    splits = splits + 1
    last_spawn = spawn
    return pane(100 + splits)
  end
  panes[id] = p
  return p
end
local wezterm = {
  GLOBAL = {}, action = {}, mux = {
    get_pane = function(id)
      if not panes[id] then error('closed pane') end
      return panes[id]
    end,
  },
}
local snapshots = {}
wezterm.json_encode = function(value)
  local snapshot = {}
  for k, v in pairs(value) do
    snapshot[k] = { pane_id = v.pane_id, invoker_id = v.invoker_id }
  end
  snapshots[#snapshots + 1] = snapshot
  return tostring(#snapshots)
end
wezterm.json_parse = function(value)
  local result = {}
  for k, v in pairs(snapshots[tonumber(value)]) do
    result[k] = { pane_id = v.pane_id, invoker_id = v.invoker_id }
  end
  return result
end
package.loaded.wezterm = wezterm
local path = 'config/wezterm/toggle_terminal/init.lua'
local toggle = dofile(path)
local source = pane(1)
local spawn = { args = {'python3', 'voice.py', '--pane-id', '1'}, size = 0.4 }
local recorder = toggle.toggle_command(nil, source, 'voice', spawn)
assert(splits == 1 and focused == 101)
assert(last_spawn.domain.DomainName == 'local' and last_spawn.args[4] == '1')
assert(last_spawn.direction == 'Bottom')
toggle.toggle_command(nil, recorder, 'voice', spawn)
assert(focused == 1 and tab.zoomed)
-- A reload and another invoking pane must not restart or retarget the recording.
toggle = dofile(path)
toggle.toggle_command(nil, pane(2), 'voice', spawn)
assert(splits == 1 and focused == 101 and not tab.zoomed)
toggle.toggle_command(nil, recorder, 'voice', spawn)
assert(focused == 1)
-- Other named command panes are independent.
toggle.toggle_command(nil, source, 'other', spawn)
assert(splits == 2)
-- A completed recorder is replaced on the next invocation.
panes[101] = nil
toggle.toggle_command(nil, source, 'voice', spawn)
assert(splits == 3 and focused == 103)
toggle.toggle_command(nil, source, 'above', { args = spawn.args, direction = 'Up' })
assert(last_spawn.direction == 'Top')
print('Toggle command tests passed')
