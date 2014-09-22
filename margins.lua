-- This helper module create a virtual margin object. This then used as a proxy
-- between the real wibox.widget.margins and the Radical menu.

local setmetatable = setmetatable
local module = {}

function module.create(widget,default)
  local mt = setmetatable({merge = function(values)
    if values.left then
      widget:set_left(values.left)
    end
    if values.right then
      widget:set_right(values.right)
    end
    if values.top then
      widget:set_top(values.top)
    end
    if values.bottom then
      widget:set_bottom(values.bottom)
    end
  end
  },{__newindex = function(tab, key,value)
    widget["set_"..key](widget,value)
  end
  ,__index=function(table,key)
    return widget[key]
  end}}
  return mt
end

return module
-- kate: space-indent on; indent-width 2; replace-tabs on;