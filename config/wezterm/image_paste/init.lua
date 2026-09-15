local wezterm = require('wezterm')
local M = {}
local checked_tools = {}
local image_tools = { 'wl-copy', 'ssh', 'ps', 'mktemp', 'timeout', 'sh', 'cat' }

local function check_tools(window, tools)
  local args = { '/bin/sh', '-c',
    'for tool do command -v "$tool" >/dev/null 2>&1 || printf "%s\\n" "$tool"; done; exit 0',
    'image-paste-check' }
  for _, tool in ipairs(tools) do
    if not checked_tools[tool] then table.insert(args, tool) end
  end
  if #args == 4 then return true end
  local ok, missing, stderr = wezterm.run_child_process(args)
  assert(ok, 'Cannot check image-paste prerequisites: ' .. stderr)
  if missing ~= '' then
    local message = 'Missing local tools: ' .. missing:gsub('%s+$', ''):gsub('\n', ', ')
      .. '. Install them and retry Ctrl+Shift+V.'
    wezterm.log_error(message)
    window:toast_notification('Image paste prerequisites missing', message, nil, 7000)
    return false
  end
  for _, tool in ipairs(tools) do checked_tools[tool] = true end
  return true
end
local formats = {
  { 'image/png', '.png' }, { 'image/jpeg', '.jpg' },
  { 'image/webp', '.webp' }, { 'image/gif', '.gif' },
  { 'image/bmp', '.bmp' }, { 'image/tiff', '.tiff' },
}

local function run(args)
  local ok, stdout, stderr = wezterm.run_child_process(args)
  if not ok then error(stderr ~= '' and stderr or (args[1] .. ' failed')) end
  return stdout
end

local function read(path)
  local file = io.open(path, 'rb')
  if not file then return nil end
  local value = file:read('*a')
  file:close()
  return value
end

local function argv_for(pid)
  local raw = read('/proc/' .. pid .. '/cmdline') or ''
  local args = {}
  for arg in raw:gmatch('([^%z]+)') do table.insert(args, arg) end
  return args
end

local function basename(path)
  return path:match('([^/]+)$') or path
end

-- Retain connection options, but never replay a remote command or forwarding.
local function ssh_target(args)
  local options, index = {}, 2
  local takes_value = 'BbcDEeFIiJLlmOopQRSWw'
  local keep = 'BbcFIiJlmop'
  local ignored_config = {
    remotecommand = true, requesttty = true, sessiontype = true,
    stdinnull = true, localforward = true, remoteforward = true,
    dynamicforward = true, forkafterauthentication = true,
  }
  while args[index] do
    local arg = args[index]
    if arg == '--' then index = index + 1; break end
    if arg:sub(1, 1) ~= '-' then break end
    if arg:sub(1, 2) == '--' then
      local option, value = arg:match('^(%-%-[^=]+)=(.*)$')
      option = option or arg
      if option == '--download-path' or option == '--upload-path' or option == '--config' then
        if not value then index = index + 1; value = args[index] end
        assert(value, 'Missing SSH option argument')
        if option == '--config' then
          table.insert(options, '-F'); table.insert(options, value)
        end
      elseif option ~= '--dragfile' and option ~= '--trzsz' then
        error('Unsupported SSH option: ' .. option)
      end
    else
      for position = 2, #arg do
        local flag = arg:sub(position, position)
        if takes_value:find(flag, 1, true) then
          local value = arg:sub(position + 1)
          if value == '' then index = index + 1; value = args[index] end
          assert(value, 'Missing SSH option argument')
          local config_key = value:match('^([^=%s]+)'):lower()
          if keep:find(flag, 1, true) and not (flag == 'o' and ignored_config[config_key]) then
            table.insert(options, '-' .. flag); table.insert(options, value)
          end
          break
        elseif ('46C'):find(flag, 1, true) then
          table.insert(options, '-' .. flag)
        elseif not ('AaCfGgKkMNnqsTtvVXxYy'):find(flag, 1, true) then
          error('Unsupported SSH option: -' .. flag)
        end
      end
    end
    index = index + 1
  end
  local host = args[index]
  assert(host and host:sub(1, 1) ~= '-', 'Cannot identify SSH destination; select a host first')
  return { host = host, options = options }
end

local function foreground(tty)
  assert(tty and tty:match('^/dev/'), 'Cannot identify terminal TTY')
  local result = {}
  local rows = run({ 'ps', '-t', tty:sub(6), '-o', 'pid=,pgid=,tpgid=' })
  for pid, group, active in rows:gmatch('(%d+)%s+(%-?%d+)%s+(%-?%d+)') do
    if group == active then
      local args = argv_for(pid)
      if args[1] then table.insert(result, { pid = pid, group = group, args = args }) end
    end
  end
  assert(#result > 0, 'Cannot inspect terminal foreground job')
  return result
end

local function tmux_tty(process, tty)
  local command, args = { process.args[1] }, process.args
  local explicit_socket = false
  for index = 2, #args do
    local flag, value = args[index]:match('^(%-[LS])(.*)$')
    if flag then
      if value == '' then value = args[index + 1] end
      assert(value, 'Missing tmux socket argument')
      table.insert(command, flag); table.insert(command, value)
      explicit_socket = true
      break
    end
  end
  if not explicit_socket then
    local env = read('/proc/' .. process.pid .. '/environ') or ''
    local socket = ('\0' .. env):match('%zTMUX=([^,%z]+),')
    if socket then table.insert(command, '-S'); table.insert(command, socket) end
  end
  for _, arg in ipairs({ 'list-clients', '-F', '#{client_pid}\t#{client_tty}\t#{pane_tty}' }) do
    table.insert(command, arg)
  end
  for pid, client_tty, pane_tty in run(command):gmatch('([^\t\n]+)\t([^\t\n]+)\t([^\n]+)') do
    if pid == process.pid and client_tty == tty then return pane_tty end
  end
  error('Cannot identify the active pane for this tmux client')
end

local function destination(window, pane)
  local domain = pane:get_domain_name()
  if domain ~= 'local' then
    for _, entry in ipairs(window:effective_config().ssh_domains or {}) do
      if entry.name == domain then
        local host, port = entry.remote_address:match('^%[([^%]]+)%]:(%d+)$')
        if not host then host, port = entry.remote_address:match('^([^:]+):(%d+)$') end
        local options = {}
        if port then table.insert(options, '-p'); table.insert(options, port) end
        if entry.username then table.insert(options, '-l'); table.insert(options, entry.username) end
        for key, value in pairs(entry.ssh_option or {}) do
          table.insert(options, '-o'); table.insert(options, key .. '=' .. value)
        end
        return { host = host or entry.remote_address, options = options }
      end
    end
    local host = domain:match('^SSH:(.+)$')
    assert(host, 'Cannot determine SSH destination for domain ' .. domain)
    return { host = host, options = {} }
  end
  local tty, seen = pane:get_tty_name(), {}
  for _ = 1, 8 do
    assert(not seen[tty], 'Circular tmux pane routing')
    seen[tty] = true
    local transports, tmux = {}, nil
    for _, process in ipairs(foreground(tty)) do
      local name = basename(process.args[1])
      if name == 'ssh' or name == 'tssh' or name == 'autossh' then
        table.insert(transports, process)
      elseif name == 'tmux' then
        tmux = process
      elseif name == 'mosh' or name == 'mosh-client' then
        error('Mosh image routing is not supported')
      end
    end
    -- Proxy/jump helpers can share their parent's foreground process group.
    -- The group leader is the interactive connection, not its transport helper.
    for _, process in ipairs(transports) do
      if process.pid == process.group then return ssh_target(process.args) end
    end
    if #transports == 1 then return ssh_target(transports[1].args) end
    if #transports > 1 then
      local ids = {}
      for _, process in ipairs(transports) do
        table.insert(ids, basename(process.args[1]) .. ':' .. process.pid)
      end
      error('Cannot select the main SSH process on ' .. tty .. ': ' .. table.concat(ids, ', '))
    end
    if not tmux then return nil end
    tty = tmux_tty(tmux, tty)
  end
  error('Too many nested tmux sessions')
end

local function transfer(path, extension, remote)
  assert(remote.host:sub(1, 1) ~= '-', 'Invalid SSH host')
  local script = 'umask 077; p=$(mktemp /tmp/wezterm-image-XXXXXXXXXXXX' .. extension .. ') || exit; '
    .. 'trap \'rm -f "$p"\' HUP INT TERM; '
    .. 'if cat > "$p"; then printf "%s\\n" "$p"; else rm -f "$p"; exit 1; fi'
  -- Binary image bytes go from file to SSH stdin, never through Lua strings or
  -- the terminal's input stream. Every variable is a distinct argv element.
  local command = {
    'timeout', '30s', 'sh', '-c', 'file=$1; shift; exec "$@" < "$file"', 'image-paste', path,
    'ssh',
  }
  for _, arg in ipairs(remote.options) do table.insert(command, arg) end
  for _, arg in ipairs({ '-T', '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10',
    '-o', 'ClearAllForwardings=yes', '-o', 'RemoteCommand=none',
    '-o', 'RequestTTY=no', '-o', 'SessionType=default', '-o', 'StdinNull=no',
    remote.host, 'sh -c ' .. wezterm.shell_quote_arg(script) }) do
    table.insert(command, arg)
  end
  local result = run(command):match('^%s*(.-)%s*$')
  assert(result:match('^/tmp/wezterm%-image%-%w+%' .. extension .. '$'), 'Remote transfer returned an invalid path')
  return result
end

local function local_image_extension(path)
  -- Reusing our own saved image path should still work after switching from a
  -- local pane to SSH. Never interpret arbitrary clipboard text as a filename.
  for _, format in ipairs(formats) do
    if path:match('^/tmp/wezterm%-image%-%w+%' .. format[2] .. '$') then
      local exists = wezterm.run_child_process({ 'sh', '-c',
        'test -f "$1" && test ! -L "$1"', 'image-paste', path })
      if exists then return format[2] end
    end
  end
end

local function copy_path(window, path, remote)
  -- wl-copy forks a clipboard owner that keeps stderr open. Capturing that
  -- pipe directly waits until the clipboard is replaced (e.g. a screenshot).
  -- Redirect both output streams before starting it, and relay startup errors
  -- from a private file after the initial process exits. The owner stays alive.
  local copied, copy_error = pcall(run, { 'sh', '-c',
    'umask 077; err=$(mktemp) || exit; trap \'rm -f "$err"\' EXIT; '
      .. 'timeout 5s wl-copy --type text/plain --trim-newline -- "$1" '
      .. '</dev/null >/dev/null 2>"$err"; status=$?; '
      .. 'if [ "$status" -ne 0 ]; then cat "$err" >&2; '
      .. 'printf "wl-copy failed (status %s)\\n" "$status" >&2; fi; exit "$status"',
    'image-paste-copy', path })
  assert(copied, 'Image saved at ' .. path .. ', but clipboard copy failed: ' .. tostring(copy_error))
  local location = (remote and remote.host or 'local') .. ': ' .. path
  wezterm.log_info('Image paste saved ' .. location)
  window:toast_notification('Image clipboard', location .. ' copied', nil, 3500)
end

function M.paste(window, pane)
  local temporary
  local ok, failure = pcall(function()
    if not check_tools(window, { 'wl-paste' }) then return end
    local types, format = run({ 'wl-paste', '--list-types' }), nil
    for _, candidate in ipairs(formats) do
      for mime in types:gmatch('[^\r\n]+') do
        if mime == candidate[1] then format = candidate; break end
      end
      if format then break end
    end
    if not format then
      assert(not types:find('image/', 1, true), 'Unsupported clipboard image format')
      local text = run({ 'wl-paste', '--no-newline' })
      local extension = local_image_extension(text)
      if extension then
        if not check_tools(window, image_tools) then return end
        local remote = destination(window, pane)
        if remote then
          text = transfer(text, extension, remote)
          copy_path(window, text, remote)
        end
      end
      pane:paste(text)
      return
    end
    if not check_tools(window, image_tools) then return end
    local remote = destination(window, pane)
    temporary = run({ 'mktemp', '/tmp/wezterm-image-XXXXXXXXXXXX' .. format[2] }):match('^%s*(.-)%s*$')
    run({ 'timeout', '15s', 'sh', '-c',
      'wl-paste --no-newline --type "$1" > "$2" && test -s "$2"',
      'image-paste', format[1], temporary })
    local path = remote and transfer(temporary, format[2], remote) or temporary
    if remote then os.remove(temporary) end
    temporary = nil -- The saved image must survive a clipboard-copy failure.
    copy_path(window, path, remote)
    pane:paste(path)
  end)
  if temporary then os.remove(temporary) end
  if not ok then
    wezterm.log_error('Image paste: ' .. tostring(failure))
    window:toast_notification('Image paste failed', tostring(failure), nil, 5000)
  end
end

-- Also useful for diagnosing routing without reading/changing the clipboard.
M.destination = destination
return M
