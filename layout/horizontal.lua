local setmetatable = setmetatable
local print,pairs = print,pairs
local unpack=unpack
local util      = require( "awful.util"       )
local button    = require( "awful.button"     )
local checkbox  = require( "radical.widgets.checkbox" )
local wibox     = require( "wibox" )
local item_layout = require("radical.item.layout.icon")
local base = nil

local module = {}

local function left(data)
  if data._current_item._tmp_menu then
    data = data._current_item._tmp_menu
    data.items.selected = true
    return true,data
  end
end

local function right(data)
  if data.parent_geometry.is_menu then
    for k,v in ipairs(data.items) do
      if v._tmp_menu == data or v.sub_menu_m == data then
        v.selected = true
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

local function setup_event(data,item,args)
  --Event handling
  if data.select_on == base.event.HOVER then
    item.widget:connect_signal("mouse::enter", function() item.selected = true end)
    item.widget:connect_signal("mouse::leave", function() item.selected = false end)
  end
  data._internal.layout:add(item)
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[#buttons+1] = button({},i,args["button"..i])
    end
  end
  if not buttons[3] then --Hide on right click
    buttons[#buttons+1] = button({},3,function()
      data.visible = false
      if data.parent_geometry and data.parent_geometry.is_menu then
        data.parent_geometry.visible = false
      end
    end)
  end

  --Be sure to always hide sub menus, even when data.visible is set manually
  data:connect_signal("visible::changed",function(_,vis)
    if data._tmp_menu and data.visible == false then
      data._tmp_menu.visible = false
    end
  end)
  data:connect_signal("parent_geometry::changed",function(_,vis)
    local fit_w,fit_h = data._internal.layout:fit()
    data.height = fit_h
    data.style(data)
  end)
  item.widget:buttons( util.table.join(unpack(buttons)))
end

function module:setup_item(data,item,args)
  local bg = item_layout(item,data,args)

  -- Set size
  local fit_w,fit_h = data._internal.layout:fit()
  data.width = fit_w
  data.height = fit_h
  data.style(data)
  local text_w = item._internal.text_w
  local icon_w = item._internal.icon_w

  -- Setup text
  item.set_text = function (_,value)
    if data.disable_markup then
      text_w:set_text(value)
    else
      text_w:set_markup(value)
    end
    if data.auto_resize then
      local fit_w,fit_h = text_w:fit(999,9999)
      local is_largest = item == data._internal.largest_item_h
      --TODO find new largest is item is smaller
      if not data._internal.largest_item_h_v or data._internal.largest_item_h_v < fit_h then
        data._internal.largest_item_h =item
        data._internal.largest_item_h_v = fit_h
      end
    end
  end
  item.set_icon = function (_,value)
    icon_w:set_image(value)
  end
  item:set_text(item._private_data.text)

  -- Setup tooltip
  bg:set_tooltip(item.tooltip)

  -- Set widget
  item.widget = bg
  data.item_style(item,{})
  setup_event(data,item,args)
end

--Get preferred item geometry
local function item_fit(data,item,...)
  if not data.visible then return 1,1 end
  local w, h = item._private_data._fit(...)
  return data.item_width or 70, item._private_data.height or h
end

local function new(data)
  if not base then
    base = require( "radical.base" )
  end
  local l = wibox.layout.fixed.horizontal()
  l.fit = function(a1,a2,a3)
    local result,r2 = wibox.layout.fixed.fit(a1,99999,99999)
--     return data.rowcount*(data.item_width or data.default_width),data.item_height
    if data.auto_resize and data._internal.largest_item_h then
      return data.rowcount*(data.item_width or data.default_width),data._internal.largest_item_h_v > data.item_height and data._internal.largest_item_h_v or data.item_height
    else
      return data.rowcount*(data.item_width or data.default_width),data.item_height
    end
  end
  l.add = function(l,item)
    return wibox.layout.fixed.add(l,item.widget)
  end
  l.item_fit = item_fit
  l.setup_key_hooks = module.setup_key_hooks
  l.setup_item = module.setup_item

  data:connect_signal("widget::added",function(_,item,widget)
    wibox.layout.fixed.add(l,item.widget)
    l:emit_signal("widget::updated")
  end)
  return l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
