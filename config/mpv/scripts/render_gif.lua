-- https://github.com/mpv-player/mpv/tree/master/TOOLS/lua

timePos = {["start"] = nil,     ["end"] = nil}
mputils = require 'mp.utils'

function handler_record()
  local path = mp.get_property("path")
  local dir, filename = mputils.split_path(path)

  if timePos["start"] == nil then
    timePos["start"] = mp.get_property_number("time-pos")
    mp.osd_message("Start Gif", 0.7)
    mp.msg.log("warn", timePos["start"] , "gif start time")
    return
  else
    timePos["end"] = mp.get_property_number("time-pos")
  end

    mp.osd_message("Rendering Gif",0.7)
    mp.msg.log("warn", timePos["start"] , "gif start time")
    mp.msg.log("warn", timePos["end"] , "gif end time")
    print (tostring(timePos["start"]))

    getmetatable('').__call = string.sub
    local key = (tostring(timePos["start"])(0,3))

    local cap = filename:match("(.+)%..+")
    cap = cap:gsub("%s+", "_")

    local cmd = "~/dotfiles/bin/2gif -l -r820 -f14 -s"..timePos["start"].." -t"..timePos["end"]
    .." \""..path.."\" ~/Weeb/"..cap.."_"..key..".gif"
    os.execute(cmd)

    mp.osd_message("Gif generated", 1)
    mp.msg.log("warn", "Gif generated")

    timePos["start"] = nil
end

mp.add_key_binding("g", "handler_record", handler_record)
