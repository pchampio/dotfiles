-- Companion server-side Lua. The GUI owns all bindings and appearance.
-- Save/restore keeps the tmux-resurrect policy: restart only ssh and tail.
local restart={ssh=true,tail=true}
local shells={sh=true,bash=true,zsh=true,fish=true,dash=true}
local function call(method,args) return assert(rex.call(method,args or {})) end
local function exec(argv)
  local result=assert(rex.exec(argv));assert(result.ok,result.stderr);return result.stdout
end
local function process(session,block)
  return call('com.superlogical.terminal.process',{session_id=session,block_id=block,args={}})
end
local function quote(s) return "'"..s:gsub("'","'\\''").."'" end
local function state_path(session)
  local dir=(os.getenv('XDG_STATE_HOME') or (assert(os.getenv('HOME'))..'/.local/state'))..'/wezterm-rex'
  exec{'mkdir','-p','-m','700',dir}
  exec{'chmod','700',dir}
  return dir..'/'..session:gsub('[^%w%-]','_')..'.json'
end
local function atomic_write(path,text)
  local random=assert(io.open('/dev/urandom','rb'));local suffix=random:read(12);random:close()
  suffix=suffix:gsub('.',function(c)return string.format('%02x',c:byte())end)
  local temporary=path..'.'..suffix
  local file=assert(io.open(temporary,'w'));exec{'chmod','600',temporary}
  assert(file:write(text));assert(file:close());assert(os.rename(temporary,path))
end
local function snapshot_process(session,block)
  local p=process(session,block);local foreground=p.foreground or p.child or {}
  local result={cwd=foreground.cwd,name=foreground.name}
  if restart[foreground.name] then
    -- Read actual arguments, never infer executable commands from terminal output.
    local file=assert(io.open('/proc/'..assert(foreground.pid)..'/cmdline','rb'))
    local bytes=file:read('*a');file:close()
    local current=process(session,block).foreground or {}
    assert(current.pid==foreground.pid and current.name==foreground.name,'Process changed while saving; retry save')
    result.argv={};for arg in bytes:gmatch('([^%z]+)') do result.argv[#result.argv+1]=arg end
  end
  return result
end
rex.action{
  name='wezterm_save',title='Save WezTerm session',
  run=function(ctx)
    local session=assert(ctx.session_id);local view=call('session.view',{session_id=session})
    local saved={version=1,view=view,blocks={}};local count=0
    for _,win in ipairs(view.windows) do for _,layer in ipairs(win.layers) do for _,block in ipairs(layer.blocks) do
      saved.blocks[block.block_id]=snapshot_process(session,block.block_id);saved.blocks[block.block_id].label=block.label;count=count+1
    end end end
    atomic_write(state_path(session),assert(rex.json.encode(saved)))
    return {windows=#view.windows,panes=count}
  end,
}
rex.action{
  name='wezterm_restore',title='Restore WezTerm session',
  run=function(ctx)
    local session=assert(ctx.session_id);local file=assert(io.open(state_path(session),'r'),'No saved WezTerm session')
    local saved=assert(rex.json.decode(file:read('*a')));file:close();assert(saved.version==1,'Unsupported save version')
    local current=call('session.view',{session_id=session});local windows,layers,live={}, {}, {}
    for _,win in ipairs(current.windows) do
      windows[win.window_id]=win
      for _,layer in ipairs(win.layers) do
        layers[layer.layer_id]=layer
        for _,block in ipairs(layer.blocks) do live[block.block_id]=true end
      end
    end
    -- Store replacement identities with the snapshot. Repeating restore (or
    -- restarting the GUI/server between restores) must not create duplicates.
    saved.mapping=saved.mapping or {windows={},layers={},blocks={}}
    local mapping=saved.mapping;local blocks={}
    for old in pairs(saved.blocks) do
      local id=mapping.blocks[old] or old
      if live[id] then blocks[old]=id end
    end
    local function checkpoint()atomic_write(state_path(session),assert(rex.json.encode(saved)))end
    local function layout(node,order)
      if node.block_id then
        order[#order+1]=node.block_id
        local record=saved.blocks[node.block_id] or {}
        return {block={flavor='com.superlogical.terminal.shell',label=record.label,options={cwd=record.cwd,
          shell='none',login=false,command={'/usr/bin/env','TERM=xterm-256color','COLORTERM=truecolor','TERM_PROGRAM=WezTerm',
            '/bin/sh','-c','exec "${SHELL:-/bin/sh}" -l -i'}}}}
      end
      local split=node.split
      return {split={direction=split.direction,ratio=split.ratio,before=layout(split.before,order),after=layout(split.after,order)}}
    end
    local function remember(order,result)
      for i,id in ipairs(order) do blocks[id]=result.block_ids[i];mapping.blocks[id]=result.block_ids[i] end
    end
    local function survivors(node,ids)
      if node.block_id then if blocks[node.block_id] then ids[blocks[node.block_id]]=true end
      else survivors(node.split.before,ids);survivors(node.split.after,ids) end
    end
    local function anchor(node)
      local ids={};survivors(node,ids)
      local function find(root)
        if root.block_id then return ids[root.block_id] and root.block_id end
        local a,b=find(root.split.before),find(root.split.after)
        if a and b then return root.split.split_id or root.split_id end
        return a or b
      end
      local view=call('session.view',{session_id=session})
      for _,win in ipairs(view.windows) do for _,layer in ipairs(win.layers) do
        local id=find(layer.layout);if id then return id end
      end end
    end
    local function repair(node)
      if node.block_id then return blocks[node.block_id]~=nil end
      local split=node.split
      local a,b=repair(split.before),repair(split.after)
      if a~=b then
        local order={};local missing=a and split.after or split.before
        local result=call('session.new_split',{session_id=session,anchor_id=assert(anchor(a and split.before or split.after)),
          direction=split.direction,side=a and 'after' or 'before',ratio=split.ratio,layout=layout(missing,order),focus=false})
        remember(order,result);checkpoint();return true
      end
      return a or b
    end
    local created=0
    for _,win in ipairs(saved.view.windows) do
      local wid=mapping.windows[win.window_id] or win.window_id
      if not windows[wid] then
        local order={};local root=layout(win.layers[1].layout,order)
        local new=call('session.new_window',{session_id=session,window_label=win.label,layout=root,focus=false});created=created+1
        wid=new.window_id;mapping.windows[win.window_id]=wid
        remember(order,new);checkpoint()
      else repair(win.layers[1].layout) end
      for i=2,#win.layers do
        local layer=win.layers[i];local lid=mapping.layers[layer.layer_id] or layer.layer_id
        if not layers[lid] then
          local order={}
          local added=call('session.new_layer',{session_id=session,window_id=wid,bounds=layer.bounds,layout=layout(layer.layout,order),focus=false})
          mapping.layers[layer.layer_id]=added.layer_id;remember(order,added);checkpoint()
          if layer.state=='minimized' then call('session.set_layer_state',{session_id=session,layer_id=added.layer_id,state='minimized'}) end
        else repair(layer.layout) end
      end
    end
    local restarted=0
    for old,block in pairs(blocks) do
      local record=saved.blocks[old]
      if record and record.argv and #record.argv>0 then
        local p=process(session,block);local foreground=p.foreground or p.child or {}
        if shells[foreground.name] then
          local args={};for _,arg in ipairs(record.argv) do args[#args+1]=quote(arg) end
          local command=(record.cwd and ('cd '..quote(record.cwd)..' && ') or '')..table.concat(args,' ')
          call('block.event',{session_id=session,block_id=block,event={type='paste',payload={text=command}}})
          call('block.event',{session_id=session,block_id=block,event={type='key',payload={key='enter',action='press',mods=''}}})
          restarted=restarted+1
        end
      end
    end
    return {windows_created=created,processes_restarted=restarted}
  end,
}
rex.action{
  name='wezterm_capture',title='Capture pane history',args={path='string'},
  run=function(ctx,args)
    local target={session_id=assert(ctx.session_id),block_id=assert(ctx.block_id),args={format='text',unwrap=true,trim=true,max_bytes=1024*1024}}
    local result=call('com.superlogical.terminal.format',target);local pieces={result.content};local length=#result.content
    while result.id and not result.eof do
      target.args={id=result.id,offset=length,max_bytes=1024*1024};result=call('com.superlogical.terminal.blob_read',target)
      pieces[#pieces+1]=result.data;length=length+#result.data;assert(length<=64*1024*1024,'History exceeds 64 MiB')
    end
    local path=args.path:gsub('^~/',assert(os.getenv('HOME'))..'/')
    atomic_write(path,table.concat(pieces));return {bytes=length}
  end,
}

-- Rex reports the foreground process group leader. In zsh command
-- substitutions that is another zsh, while fzf is a descendant in that group.
rex.action{
  name='wezterm_input_processes',title='Foreground terminal input processes',
  run=function(ctx)
    local p=process(assert(ctx.session_id),assert(ctx.block_id))
    local foreground=p.foreground or p.child or {}
    local function read(path)
      local file=io.open(path,'r');if not file then return '' end
      local value=file:read('*a');file:close();return value
    end
    local function group(pid)
      return read('/proc/'..pid..'/stat'):match('^%d+ %(.+%) %S+ %d+ (%d+)')
    end
    local names,seen,count={}, {},0
    local root=foreground.pid and tostring(foreground.pid)
    local pgid=root and group(root)
    local function visit(pid)
      if seen[pid] or count>=128 then return end
      seen[pid]=true;count=count+1
      if pgid and group(pid)==pgid then
        local name=read('/proc/'..pid..'/comm'):gsub('%s+$','')
        if name~='' then names[#names+1]=name end
      end
      for child in read('/proc/'..pid..'/task/'..pid..'/children'):gmatch('%d+') do visit(child) end
    end
    if root then visit(root) end
    return {pid=foreground.pid,names=names}
  end,
}

rex.action{
  name='wezterm_split_context',title='Resolve shell or SSH split',
  run=function(ctx,args)
    local session,block=assert(ctx.session_id),assert(ctx.block_id)
    local p=snapshot_process(session,block)
    if p.name~='ssh' then return {cwd=p.cwd} end
    -- Preserve connection options, strip the old remote command, and request
    -- an interactive PTY. Arguments remain an array throughout the API.
    local argv=p.argv;local command={argv[1]};local i=2;local host
    local takes_value={B=true,b=true,c=true,D=true,E=true,e=true,F=true,I=true,i=true,J=true,L=true,l=true,m=true,O=true,o=true,p=true,Q=true,R=true,S=true,W=true,w=true}
    while i<=#argv do
      local arg=argv[i]
      if arg=='--' then i=i+1;host=argv[i];break end
      if arg:sub(1,1)~='-' then host=arg;break end
      local flags=arg:sub(2);local kept='';local j=1
      while j<=#flags do
        local flag=flags:sub(j,j)
        if takes_value[flag] then
          if kept~='' then command[#command+1]='-'..kept;kept='' end
          local value=flags:sub(j+1)
          if value=='' then i=i+1;value=assert(argv[i],'Missing SSH option value') end
          if flag~='O' and flag~='W' and flag~='Q' and not (flag=='o' and value:lower():match('^remotecommand[= ]')) then
            command[#command+1]='-'..flag;command[#command+1]=value
          end
          break
        elseif flag~='N' and flag~='n' and flag~='f' and flag~='T' then kept=kept..flag end
        j=j+1
      end
      if kept~='' then command[#command+1]='-'..kept end
      i=i+1
    end
    assert(host,'Cannot find SSH destination')
    command[#command+1]='-t';command[#command+1]='-o';command[#command+1]='RemoteCommand=none';command[#command+1]=host
    if args and args.remote_cwd then
      command[#command+1]='cd -- '..quote(args.remote_cwd)..' && exec "${SHELL:-/bin/sh}" -l'
    end
    return {cwd=p.cwd,command=command}
  end,
}

rex.action{
  name='wezterm_environment',title='Find pane environment',
  run=function(ctx)
    local p=process(assert(ctx.session_id),assert(ctx.block_id));p=p.foreground or p.child or {}
    local env={};local file=p.pid and io.open('/proc/'..p.pid..'/environ','rb')
    if file then
      for pair in file:read('*a'):gmatch('[^%z]+') do
        local key,value=pair:match('^([^=]+)=(.*)$')
        if key=='VIRTUAL_ENV' or key=='CONDA_PREFIX' then env[key]=value end
      end
      file:close()
    end
    local prefix=env.VIRTUAL_ENV or env.CONDA_PREFIX
    local root=p.cwd
    while root and root~='' do
      local f=io.open(root..'/env.sh','r')
      if f then f:close();break end
      root=root:match('^(.*)/[^/]+$')
    end
    if (not root or root=='') and prefix then
      local candidate=prefix..'/../..';local f=io.open(candidate..'/env.sh','r')
      if f then f:close();root=candidate end
    end
    return {home=os.getenv('HOME'),root=root~='' and root or nil,prefix=prefix,python=prefix and prefix..'/bin/python3' or 'python3'}
  end,
}

-- Session copy buffers live on the server, independently of the desktop
-- clipboard and of which GUI/device is currently attached. Chunking keeps
-- large selections below the control channel's negotiated message limit.
local pending_buffers={}
local function buffer_path(session)return state_path(session)..'.buffer'end
rex.action{
  name='wezterm_buffer_begin',title='Begin session copy',
  run=function(ctx)
    local random=assert(io.open('/dev/urandom','rb'));local token=random:read(16);random:close()
    token=token:gsub('.',function(c)return string.format('%02x',c:byte())end)
    local session=assert(ctx.session_id);local path=buffer_path(session)..'.'..token
    local file=assert(io.open(path,'wb'));file:close();exec{'chmod','600',path}
    pending_buffers[token]={path=path,session=session,size=0}
    return {token=token}
  end,
}
rex.action{
  name='wezterm_buffer_append',title='Write session copy',args={token='string',text='string',finish='boolean'},
  run=function(ctx,args)
    assert(type(args.token)=='string' and #args.token==32 and args.token:match('^%x+$'),'Invalid copy transaction')
    local pending=pending_buffers[args.token]
    if not pending then
      local path=buffer_path(assert(ctx.session_id))..'.'..args.token
      local file=assert(io.open(path,'rb'),'Unknown copy transaction')
      local size=assert(file:seek('end'));file:close()
      pending={path=path,size=size,session=ctx.session_id};pending_buffers[args.token]=pending
    end
    assert(pending.session==ctx.session_id,'Copy transaction belongs to another session')
    pending.size=pending.size+#args.text
    if pending.size>16*1024*1024 then os.remove(pending.path);pending_buffers[args.token]=nil;error('Copy exceeds 16 MiB') end
    local file=assert(io.open(pending.path,'ab'));assert(file:write(args.text));assert(file:close())
    if args.finish then assert(os.rename(pending.path,buffer_path(pending.session)));pending_buffers[args.token]=nil end
    return {bytes=pending.size}
  end,
}
rex.action{
  name='wezterm_buffer_read',title='Read session copy',args={offset='integer'},
  run=function(ctx,args)
    assert(args.offset>=0 and args.offset<=16*1024*1024,'Invalid copy offset')
    local file=io.open(buffer_path(assert(ctx.session_id)),'rb')
    if not file then return {text='',eof=true} end
    file:seek('set',args.offset)
    local text=file:read(8192) or ''
    -- Do not split UTF-8 in the JSON response. Complete the last codepoint.
    if #text>0 then
      local i=#text;while i>0 and text:byte(i)>=128 and text:byte(i)<192 do i=i-1 end
      local lead=text:byte(i) or 0;local width=lead>=240 and 4 or lead>=224 and 3 or lead>=192 and 2 or 1
      local missing=width-(#text-i+1);if missing>0 then text=text..(file:read(missing) or '') end
    end
    local eof=file:read(1)==nil;file:close();return {text=text,eof=eof}
  end,
}
