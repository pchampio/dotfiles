-- Optional native pane navigation for local WezTerm and Rex, including SSH.
do
  vim.g.smart_splits_multiplexer_integration=false
  local ok,splits=pcall(require,'rex_splits')
  if ok then splits.setup() end
end
-- Loaded as a Neovim plugin. Inert outside a Rex terminal.
if not vim.env.REX_SERVER or not vim.env.REX_SESSION or not vim.env.REX_BLOCK then return end
local rex=(vim.env.REX_BIN_DIR and (vim.env.REX_BIN_DIR..'/rex')) or 'rex'
local function action(name,args)
  local result=vim.fn.system({rex,'-S',vim.env.REX_SERVER,'--autostart=false','api','call','client.action',vim.fn.json_encode{
    action=name,session_id=vim.env.REX_SESSION,block_id=vim.env.REX_BLOCK,args=args or vim.empty_dict(),
  }})
  assert(vim.v.shell_error==0,result)
  return vim.fn.json_decode(result).result
end
local function encode(text)
  if vim.base64 then return vim.base64.encode(text) end
  local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local pieces={}
  for i=1,#text,3 do
    local a,b,c=text:byte(i,i+2);local value=a*65536+(b or 0)*256+(c or 0)
    local function digit(n)return alphabet:sub(n+1,n+1)end
    pieces[#pieces+1]=digit(math.floor(value/262144))..digit(math.floor(value/4096)%64)..(b and digit(math.floor(value/64)%64) or '=')..(c and digit(value%64) or '=')
  end
  return table.concat(pieces)
end
local function emit(text)
  -- Neovim 0.12+: in order with the UI's own output (see nvim-smart-splits.lua).
  if vim.api.nvim_ui_send and #vim.api.nvim_list_uis()>0 then vim.api.nvim_ui_send(text);return end
  local file=io.open('/dev/tty','w')
  if file then file:write(text);file:flush();file:close()
  elseif #vim.api.nvim_list_uis()>0 then io.stdout:write(text);io.stdout:flush() end
end
local function copy(lines,kind)
  local text=table.concat(lines,'\n')..(kind=='V' and '\n' or '')
  local token=action('wezterm_buffer_begin').token;local first=1
  repeat
    local last=math.min(#text,first+8191)
    while last<#text and text:byte(last+1)>=128 and text:byte(last+1)<192 do last=last-1 end
    action('wezterm_buffer_append',{token=token,text=text:sub(first,last),finish=last==#text});first=last+1
  until first>#text
end
local function paste()
  local parts,offset={},0
  while true do
    local part=action('wezterm_buffer_read',{offset=offset});parts[#parts+1]=part.text;offset=offset+#part.text
    if part.eof then break end
    assert(#part.text>0 and offset<=16*1024*1024,'Invalid Rex copy buffer')
  end
  local text=table.concat(parts);local kind=text:sub(-1)=='\n' and 'V' or 'v'
  if kind=='V' then text=text:sub(1,-2) end
  return {vim.split(text,'\n',{plain=true}),kind}
end
local function configure()
  local old=type(vim.g.clipboard)=='table' and vim.g.clipboard or {}
  local plus_paste=old.paste and old.paste['+']
  if not plus_paste then
    local ok,osc=pcall(require,'vim.ui.clipboard.osc52');if ok then plus_paste=osc.paste('+') end
  end
  vim.g.clipboard={name='Rex session and desktop',cache_enabled=0,
    copy={['*']=copy,['+']=function(lines,kind)
      emit('\27]52;c;'..encode(table.concat(lines,'\n')..(kind=='V' and '\n' or ''))..'\7')
    end},paste={['*']=paste,['+']=plus_paste or function()return {{},'v'}end}}
end
local group=vim.api.nvim_create_augroup('WezTermRex',{clear=true})
local exiting=false
vim.api.nvim_create_autocmd({'VimEnter','ModeChanged'},{group=group,callback=function()
  local mode=vim.fn.mode()
  vim.schedule(function()if not exiting then emit('\27]1337;SetUserVar=NVIM_MODE='..encode(mode)..'\7') end end)
end})
vim.api.nvim_create_autocmd('VimLeavePre',{group=group,callback=function()exiting=true;emit('\27]1337;SetUserVar=NVIM_MODE=\7')end})
vim.api.nvim_create_autocmd('VimEnter',{group=group,callback=configure})
configure()
