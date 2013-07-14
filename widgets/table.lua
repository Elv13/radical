local wibox = require("wibox")
local ipairs = ipairs
local print = print

local function new(content)
  local rows = #content
  local cols = 0
  for k,v in ipairs(content) do
    if #v > cols then
      cols = #v
    end
  end
  local main_l = wibox.layout.fixed.vertical()
  local w =200
  main_l.fit = function(self,width,height)
    w = width
    return wibox.layout.fixed.fit(self,width,height)
  end
  for k,v in  ipairs(content) do
    local row_l = wibox.layout.fixed.horizontal()
    for i=1,cols do
      local t = wibox.widget.textbox()
      t.fit = function(...)
        local fw,fh = wibox.widget.textbox.fit(...)
        return w/4,fh
      end
      t:set_text(v[i])
      row_l:add(t)
    end
    main_l:add(row_l)
  end
  return main_l
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
