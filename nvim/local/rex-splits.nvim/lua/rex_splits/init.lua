-- rex-splits.nvim: Neovim windows first, native WezTerm/Rex panes at an edge.
-- Uses terminal OSC messages, including through SSH; no wezterm CLI/socket.
local M = {}
local directions = {h='Left', j='Down', k='Up', l='Right'}
local serial = 0
local function encode(text)
  if vim.base64 then return vim.base64.encode(text) end
  local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local out={}
  for i=1,#text,3 do
    local a,b,c=text:byte(i,i+2);local n=a*65536+(b or 0)*256+(c or 0)
    local function digit(v)return alphabet:sub(v+1,v+1)end
    out[#out+1]=digit(math.floor(n/262144))..digit(math.floor(n/4096)%64)..(b and digit(math.floor(n/64)%64) or '=')..(c and digit(n%64) or '=')
  end
  return table.concat(out)
end
local function emit(name,value)
  local file=io.open('/dev/tty','w')
  local sequence='\27]1337;SetUserVar='..name..'='..encode(value)..'\7'
  -- Neovim 0.12+: the UI sends the bytes in order with its own output. A
  -- write to /dev/tty can land inside a sequence of the UI and get lost.
  if vim.api.nvim_ui_send and #vim.api.nvim_list_uis()>0 then
    if file then file:close() end
    vim.api.nvim_ui_send(sequence);return true
  end
  if file then file:write(sequence);file:flush();file:close();return true end
  -- Neovim's separate TUI process can leave the editor without a controlling
  -- /dev/tty. Its stdout still forwards terminal sequences to that TUI.
  if #vim.api.nvim_list_uis()>0 then io.stdout:write(sequence);io.stdout:flush();return true end
  return false
end
local function request(action,key,amount)
  serial=serial+1
  local value=vim.fn.json_encode{version=1,action=action,direction=assert(directions[key]),amount=amount,serial=serial}
  return emit('WEZTERM_PANE_REQUEST',value)
end
function M.move(key)
  assert(directions[key],'Expected h, j, k or l')
  local before=vim.api.nvim_get_current_win()
  vim.cmd('wincmd '..key)
  if vim.api.nvim_get_current_win()==before then request('move',key) end
end
function M.resize(key,amount)
  assert(directions[key],'Expected h, j, k or l')
  amount=amount or M.amount or 6
  if vim.fn.winnr(key)==vim.fn.winnr() then return request('resize',key,amount) end
  local horizontal=key=='h' or key=='l'
  local delta=(key=='h' or key=='k') and -amount or amount
  vim.cmd((horizontal and 'vertical ' or '')..'resize '..(delta>=0 and '+' or '')..delta)
end
function M.setup(opts)
  opts=opts or {};M.amount=opts.default_amount or 6
  -- Disable upstream CLI autodetection even if another config loads it later.
  vim.g.smart_splits_multiplexer_integration=false
  local group=vim.api.nvim_create_augroup('RexSplits',{clear=true})
  local exiting=false
  vim.api.nvim_create_autocmd({'VimEnter','ModeChanged'},{group=group,callback=function()
    local mode=vim.fn.mode()
    vim.schedule(function()if not exiting then emit('NVIM_MODE',mode) end end)
  end})
  vim.api.nvim_create_autocmd('VimLeavePre',{group=group,callback=function()exiting=true;emit('NVIM_MODE','')end})
  if vim.v.vim_did_enter==1 then emit('NVIM_MODE',vim.fn.mode()) end
  for _,key in ipairs{'h','j','k','l'} do
    vim.keymap.set({'n','x'},'<C-'..key..'>',function()M.move(key)end,{silent=true,desc='Move to '..directions[key]..' window/pane'})
    vim.keymap.set('t','<C-'..key..'>',function()
      vim.cmd('stopinsert');vim.schedule(function()M.move(key)end)
    end,{silent=true,desc='Move to '..directions[key]..' window/pane'})
  end
end
return M
