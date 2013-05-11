local setmetatable = setmetatable
local print = print
local wibox     = require( "wibox" )

local module = {}

local function left(data)
  if data._current_item._tmp_menu then
    data = data._current_item._tmp_menu
    data.items[1][1].selected = true
    return true,data
  end
end

local function right(data)
  if data.parent_geometry.is_menu then
    for k,v in ipairs(data.items) do
      if v[1]._tmp_menu == data or v[1].sub_menu_m == data then
        v[1].selected = true
      end
    end
    data.visible = false
    data = data.parent_geometry
    return true,data
  end
end

local function up(data)
  data.previous_item.selected = true
end

local function down(data)
  data.next_item.selected = true
end

function module:setup_key_hooks(data)
  data:add_key_hook({}, "Up"      , "press", up    )
  data:add_key_hook({}, "&"       , "press", up    )
  data:add_key_hook({}, "Down"    , "press", down  )
  data:add_key_hook({}, "KP_Enter", "press", down  )
  data:add_key_hook({}, "Left"    , "press", left  )
  data:add_key_hook({}, "\""      , "press", left  )
  data:add_key_hook({}, "Right"   , "press", right )
  data:add_key_hook({}, "#"       , "press", right )
end

--Get preferred item geometry
local function item_fit(data,item,...)
  local w, h = item._private_data._fit(...)
  return 70, item._private_data.height or h
end

local function new(data)
  local l = wibox.layout.fixed.horizontal()
  l.fit = function(a1,a2,a3)
    local result,r2 = wibox.layout.fixed.fit(a1,99999,99999)
    return data.rowcount*data.default_width,data.item_height
  end
  l.add = function(l,item)
    return wibox.layout.fixed.add(l,item.widget)
  end
  l.item_fit = item_fit
  return l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
