-- This helper module create a virtual margin object. This then used as a proxy
-- between the real wibox.widget.margins and the Radical menu.

local setmetatable = setmetatable
local awful = require("awful")
local module = {}

local function reset_margins(margins)
  local widget = margins.widget
  if widget and margins.defaults then
    for k,v in pairs(margins.defaults) do
      local f = widget["set_"..k:lower()]
      if f then
        f(widget,v)
      end
    end
  end
end

local function new(widget,defaults)
  local mt = nil
  mt = setmetatable({defaults=awful.util.table.join(defaults,{}),widget=widget,reset=reset_margins,
    merge = function(values)
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
    key = key:lower()
    if key == "widget" then
      rawset(tab,"widget",value)
      reset_margins(tab)
    elseif widget then
      widget["set_"..key](widget,value)
    else --TODO can't do this
      mt.defaults[key] = value
    end
  end
  ,__index=function(table,key)
    local w = rawget(table,"widget")
    return w and w[key] or defaults[key] --widget["get_"..key](widget)
  end})

  reset_margins(mt)

  return mt
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
