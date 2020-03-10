-- https://github.com/mpv-player/mpv/tree/master/TOOLS/lua

timePos = {["start"] = nil,     ["end"] = nil}
mputils = require 'mp.utils'

function handler_select()
  local path = mp.get_property("path")
  local dir, filename = mputils.split_path(path)

  if timePos["start"] == nil then
    timePos["start"] = mp.get_property_number("time-pos")
    mp.osd_message("Segment Start", 0.7)
    mp.msg.log("warn", timePos["start"] , "gif start time")
    return
  else
    timePos["end"] = mp.get_property_number("time-pos")
  end

    mp.osd_message("Segment Start",0.7)

    getmetatable('').__call = string.sub
    local key = (tostring(timePos["start"])(0,3))

    local cap = filename:match("(.+)%..+")
    cap = cap:gsub("%s+", "_")


    local duration = timePos["end"] - timePos["start"]
    mp.msg.log("warn","duration ", duration)

    local cmd = "echo '\""..path.."\": "..timePos["start"].." -> "..timePos["end"]
    .."' >> ~/Downloads/gopro.rush"
    os.execute(cmd)

    mp.osd_message("Segment length "..duration, 1)

    timePos["start"] = nil
end

mp.add_key_binding("n", "handler_select", handler_select)
