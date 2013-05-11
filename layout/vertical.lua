local setmetatable = setmetatable
local print = print
local beautiful = require("beautiful")
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
  return w, item._private_data.height or h
end

local function new(data)
  local l,real_l = wibox.layout.fixed.vertical(),nil
  local filter_tb = nil
  if data.show_filter then
    real_l = wibox.layout.fixed.vertical()
    real_l:add(l)
    filter_tb = wibox.widget.textbox()
    local bg = wibox.widget.background()
    bg:set_bg(beautiful.bg_highlight)
    bg:set_widget(filter_tb)
    filter_tb:set_markup("<b>Filter:</b>")
    filter_tb.fit = function(tb,width,height)
      return width,data.item_height
    end
    data:connect_signal("filter_string::changed",function()
      filter_tb:set_markup("<b>Filter:</b> "..data.filter_string)
    end)
    real_l:add(bg)
  else
    real_l = l
  end
  real_l.fit = function(a1,a2,a3)
    local result,r2 = wibox.layout.fixed.fit(a1,99999,99999)
    local total = data._total_item_height
    return data.default_width, (total and total > 0 and total or data.rowcount*data.item_height) + (filter_tb and data.item_height or 0)
  end
  real_l.add = function(real_l,item)
    return wibox.layout.fixed.add(l,item.widget)
  end
  real_l.item_fit = item_fit
  return real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
