return {
  -- show line number with only left side(1~5) number to convenient manipulate
  'pchampio/comfy-line-numbers.nvim',
  branch = 'gitsigns.nvim',
--   init = function() 
--   local comfy = require 'comfy-line-numbers'
--   local function strip_padding(str)
--   return tostring(str):gsub("^%s+", "")
-- end
-- comfy.register_line_hook('highlight_226', function(lnum, data)
--   if lnum == 10 then
--     local stripped = strip_padding(data.num)
--     data.num = '%#ErrorMsg#' .. stripped .. '%*'
--   end
--     data.git = ' ' .. data.git .. ' '
--   return data
-- end)
--   end,
  opts = {
    labels = {
      '','1','','2','','3','','4','','5','','11','','12','','13','','14','','15','','22','','23','','24','','25','','33','','34','','35','','44','','45','','55','',
      '123','', '124','','125','','234','', '235'
    },
  }
}
