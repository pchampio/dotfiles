-- lua config/wezterm/image_paste/test.lua
local commands, removed, notices, pasted = {}, {}, {}, {}
local clipboard, remote_failure, mime, ps, proc, client_rows = nil, false, 'image/png', {}, {}, ''
local text, local_file = 'plain text', false
local missing_tools = {}
local copy_failure = false
local window = { effective_config = function() return { ssh_domains = {} } end }
function window:toast_notification(title, text) table.insert(notices, {title, text}) end
local pane = {
  get_domain_name = function() return 'local' end,
  get_tty_name = function() return '/dev/pts/1' end,
  paste = function(_, text) table.insert(pasted, text) end,
}
local fake = {
  shell_quote_arg = function(s) return "'" .. s:gsub("'", "'\\''") .. "'" end,
  log_error = function() end,
  log_info = function() end,
}
function fake.run_child_process(args)
  table.insert(commands, args)
  if args[1] == '/bin/sh' and args[4] == 'image-paste-check' then
    local missing = ''
    for i = 5, #args do
      if missing_tools[args[i]] then missing = missing .. args[i] .. '\n' end
    end
    return true, missing, ''
  end
  if args[1] == 'ps' then return true, assert(ps[args[3]]), '' end
  if args[1] == 'tmux' then return true, client_rows, '' end
  if args[1] == 'wl-paste' then return true, args[2] == '--list-types' and mime .. '\n' or text, '' end
  if args[1] == 'sh' and args[4] == 'image-paste-copy' then
    if copy_failure then return false, '', 'clipboard unavailable' end
    clipboard = args[#args]; return true, '', ''
  end
  if args[1] == 'sh' then return local_file, '', '' end
  if args[1] == 'mktemp' then return true, '/tmp/wezterm-image-LOCAL123.png\n', '' end
  if args[1] == 'timeout' then
    if args[2] == '30s' then
      if remote_failure then return false, '', 'SSH failed' end
      return true, '/tmp/wezterm-image-REMOTE123.png\n', ''
    end
    return true, '', ''
  end
  error('Unexpected command: ' .. table.concat(args, ' '))
end
package.loaded.wezterm = fake
local open = io.open
io.open = function(path, mode)
  if path:match('^/proc/') then
    local value = proc[path]
    if not value then return nil end
    return { read = function() return value end, close = function() end }
  end
  return open(path, mode)
end
os.remove = function(path) table.insert(removed, path); return true end
local plugin = dofile('config/wezterm/image_paste/init.lua')
local function reset()
  plugin = dofile('config/wezterm/image_paste/init.lua')
  missing_tools = {}
  copy_failure = false
  commands, removed, notices, pasted = {}, {}, {}, {}
  clipboard, remote_failure, mime = nil, false, 'image/png'
  text, local_file = 'plain text', false
  ps = { ['pts/1'] = '10 10 10\n99 99 10\n' }
  proc = { ['/proc/10/cmdline'] = 'zsh\0', ['/proc/99/cmdline'] = 'ssh\0unrelated-background-host\0' }
end
reset()
assert(plugin.destination(window, pane) == nil, 'background SSH must not affect destination')
plugin.paste(window, pane)
assert(clipboard == '/tmp/wezterm-image-LOCAL123.png' and pasted[1] == clipboard and #removed == 0)

reset()
copy_failure = true
plugin.paste(window, pane)
assert(#pasted == 0 and #removed == 0, 'Keep saved image after clipboard copy failure')
assert(notices[1][2]:find('Image saved at /tmp/wezterm-image-LOCAL123.png', 1, true))
assert(notices[1][2]:find('clipboard unavailable', 1, true))

reset()
mime = 'text/plain'
plugin.paste(window, pane)
assert(pasted[1] == 'plain text' and clipboard == nil)
assert(#commands == 3, 'plain text paste only checks wl-paste and reads the clipboard')

reset()
missing_tools = { ['wl-paste'] = true }
plugin.paste(window, pane)
assert(#commands == 1 and #pasted == 0 and clipboard == nil)
assert(notices[1][1] == 'Image paste prerequisites missing')
assert(notices[1][2]:find('wl-paste', 1, true))
missing_tools = {}
plugin.paste(window, pane)
assert(pasted[1] == clipboard, 'Installing a missing tool should work on the next paste')

reset()
missing_tools = { ssh = true, ['wl-copy'] = true }
plugin.paste(window, pane)
assert(#pasted == 0 and clipboard == nil and #removed == 0)
assert(notices[1][2]:find('ssh', 1, true) and notices[1][2]:find('wl-copy', 1, true))
mime = 'text/plain'
plugin.paste(window, pane)
assert(pasted[1] == 'plain text', 'Missing image tools must not block ordinary text paste')

reset()
proc['/proc/10/cmdline'] = 'tssh\0--download-path\0/tmp/\0-p2222\0-J\0jump\0ampere\0tmux attach\0'
local target = plugin.destination(window, pane)
assert(target.host == 'ampere' and table.concat(target.options, ' ') == '-p 2222 -J jump')
-- A ProxyJump helper is in the same foreground group, but is not the target.
ps['pts/1'] = '11 10 10\n10 10 10\n'
proc['/proc/11/cmdline'] = 'ssh\0-W\0ampere:22\0jump\0'
assert(plugin.destination(window, pane).host == 'ampere')
plugin.paste(window, pane)
assert(clipboard == '/tmp/wezterm-image-REMOTE123.png' and #removed == 1 and pasted[1] == clipboard)
local transfer
for _, args in ipairs(commands) do if args[2] == '30s' then transfer = args end end
assert(transfer and not table.concat(transfer, ' '):find('tmux attach', 1, true))

reset()
proc['/proc/10/cmdline'] = 'tmux\0-L\0work\0attach\0'
client_rows = '55\t/dev/pts/9\t/dev/pts/8\n10\t/dev/pts/1\t/dev/pts/4\n'
ps['pts/4'] = '20 20 20\n'
proc['/proc/20/cmdline'] = 'ssh\0-o\0RemoteCommand=bad\0-R\08080:localhost:80\0ampere\0'
assert(plugin.destination(window, pane).host == 'ampere')
assert(#plugin.destination(window, pane).options == 0)
proc['/proc/20/cmdline'] = 'codex\0'
assert(plugin.destination(window, pane) == nil)

reset()
proc['/proc/10/cmdline'] = 'ssh\0ampere\0'
remote_failure = true
plugin.paste(window, pane)
assert(clipboard == nil and #removed == 1 and #pasted == 0)
assert(notices[1][1] == 'Image paste failed')

reset()
mime, text, local_file = 'text/plain', '/tmp/wezterm-image-LOCAL123.png', true
proc['/proc/10/cmdline'] = 'tssh\0ampere\0'
plugin.paste(window, pane)
assert(clipboard == '/tmp/wezterm-image-REMOTE123.png' and pasted[1] == clipboard)
assert(#removed == 0, 'Keep the original local image for reuse')

reset()
mime, text = 'text/plain', '/tmp/wezterm-image-REMOTE123.png'
plugin.paste(window, pane)
assert(pasted[1] == text and clipboard == nil, 'Remote-only paths should paste as text')

reset()
mime, text, local_file = 'text/plain', '/tmp/wezterm-image-LOCAL123.png', true
proc['/proc/10/cmdline'] = 'ssh\0ampere\0'
remote_failure = true
plugin.paste(window, pane)
assert(clipboard == nil and #pasted == 0, 'Do not paste a local path after failed upload')

reset()
local remote_pane = { get_domain_name = function() return 'native' end }
window.effective_config = function()
  return { ssh_domains = {{ name = 'native', remote_address = 'server:2222', username = 'alice' }} }
end
local native = plugin.destination(window, remote_pane)
assert(native.host == 'server' and table.concat(native.options, ' ') == '-p 2222 -l alice')
print('Image paste tests passed: local, text, SSH/tssh, targeted tmux, native SSH, transfer failure')
