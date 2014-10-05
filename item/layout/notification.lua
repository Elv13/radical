local setmetatable = setmetatable
local beautiful = require( "beautiful"    )
local color     = require( "gears.color"  )
local cairo     = require( "lgi"          ).cairo
local wibox     = require( "wibox"        )
local checkbox  = require( "radical.widgets.checkbox"  )
local fkey      = require( "radical.widgets.fkey"      )
local underlay  = require( "radical.widgets.underlay"  )
local theme     = require( "radical.theme"             )
local horizontal= require( "radical.item.layout.horizontal")

local module = {}


-- Add [F1], [F2] ... to items
function module:setup_fkey(item,data)
  item.set_f_key = function(_,value)
    item._internal.has_changed = true
    item._internal.f_key = value
    data:remove_key_hook("F"..value)
    data:add_key_hook({}, "F"..value      , "press", function()
      item.button1(data,menu)
      data.visible = false
    end)
  end
  item.get_f_key = function() return item._internal.f_key end
end

-- Like an overlay, but under
function module.paint_underlay(data,item,cr,width,height)
  cr:save()
  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = theme.colors_by_id[current_state] or ""
  local udl = underlay.draw(item.underlay,{style=data.underlay_style,height=height,bg=data["underlay_bg_"..state_name]})
  cr:set_source_surface(udl,width-udl:get_width()-3)
  cr:paint_with_alpha(data.underlay_alpha)
  cr:restore()
end

-- Show the checkbox
function module:setup_checked(item,data)
  if item.checkable then
    item.get_checked = function()
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked()
      else
        return item._private_data.checked
      end
    end
    local ck = wibox.widget.imagebox()
    ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    item.set_checked = function (_,value)
      item._private_data.checked = value
      ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
      item._internal.has_changed = true
    end
    return ck
  end
end

-- Setup hover
function module:setup_hover(item,data)
  item.set_hover = function(_,value)
    local item_style = item.item_style or data.item_style
    item.state[-1] = value and true or nil
    item_style(item,{})
  end
end

-- Create sub_menu arrows
local sub_arrow = nil
function module:setup_sub_menu_arrow(item,data)
  if item._private_data.sub_menu_f or item._private_data.sub_menu_m then
    if not sub_arrow then
      sub_arrow = wibox.widget.imagebox() --TODO, make global
      sub_arrow.fit = function(box, w, h) return sub_arrow._image:get_width(),item.height end
      sub_arrow:set_image( beautiful.menu_submenu_icon   )
    end
    return sub_arrow
  end
end

-- Proxy all events to the parent
function module.setup_event(data,item,widget)
  local widget = widget or item.widget

  -- Setup data signals
  widget:connect_signal("button::press",function(_,__,___,id,mod)
    local mods_invert = {}
    for k,v in ipairs(mod) do
      mods_invert[v] = i
    end

    item.state[4] =  true
    data:emit_signal("button::press",item,id,mods_invert)
    item:emit_signal("button::press",item,id,mods_invert)
  end)
  widget:connect_signal("button::release",function(_,__,___,id,mod)
    local mods_invert = {}
    for k,v in ipairs(mod) do
      mods_invert[v] = i
    end
    item.state[4] =  nil
    data:emit_signal("button::release",item,id,mods_invert)
    item:emit_signal("button::release",item,id,mods_invert)
  end)
  widget:connect_signal("mouse::enter",function(b,t)
    data:emit_signal("mouse::enter",item)
    item:emit_signal("mouse::enter",item)
  end)
  widget:connect_signal("mouse::leave",function(b,t)
    data:emit_signal("mouse::leave",item)
    item:emit_signal("mouse::leave",item)
  end)

  -- Always tracking mouse::move is expensive, only do it when necessary
--   local function conn(b,t)
--     item:emit_signal("mouse::move",item)
--   end
--   item:connect_signal("connection",function(_,name,count)
--     if name == "mouse::move" then
--       widget:connect_signal("mouse::move",conn)
--     end
--   end)
--   item:connect_signal("disconnection",function(_,name,count)
--     if count == 0 then
--       widget:connect_signal("mouse::move",conn)
--     end
--   end)
end

-- Use all the space, let "align_fit" compute the right size
local function textbox_fit(box,w,h)
  local w2,h2 = wibox.widget.textbox.fit(box,w,h)
  return w,h2
end

-- Force the width or compute the minimum space
local function align_fit(box,w,h)
  if box._item.width then return box._item.width - box._data.item_style.margins.LEFT - box._data.item_style.margins.RIGHT,h end
  return box.first:fit(w,h)+wibox.widget.textbox.fit(box.second,w,h)+box.third:fit(w,h),h
end

-- Create the actual widget
local function create_item(item,data,args)
  -- Background
  local bg = wibox.widget.background()

  -- Margins
  local m = wibox.layout.margin(la)
  local mrgns = margins2(m,(item.item_style or data.item_style).margins)
  item.get_margins = function()
    return mrgns
  end

  -- Layout (left)
  local layout = wibox.layout.fixed.horizontal()
  bg:set_widget(m)

  -- Layout (right)
  local right = wibox.layout.fixed.horizontal()

  -- F keys
  module:setup_fkey(item,data)
  if data.fkeys_prefix == true then
    layout:add(fkey(data,item))
  end

  -- Icon
  local icon = horizontal.setup_icon(horizontal,item,data)
  icon.fit = function(...)
    local w,h = wibox.widget.imagebox.fit(...)
    return w+3,h
  end
  layout:add(icon)

  -- Prefix
  if args.prefix_widget then
    layout:add(args.prefix_widget)
  end

  -- Checkbox
  local ck = module:setup_checked(item,data)
  if ck then
    right:add(ck)
  end

  -- Hover
  module:setup_hover(item,data)

  -- Sub_arrow
  local ar = module:setup_sub_menu_arrow(item,data)
  if ar then
    right:add(ar)
  end

  -- Suffix
  if args.suffix_widget then
    right:add(args.suffix_widget)
  end

  -- Vertical text layout
  local vert = wibox.layout.fixed.vertical()
--   vert:add(tb)

  -- Text
  local tb4 = wibox.widget.textbox()
  tb4.draw = function(self,w, cr, width, height)
    if item.underlay then
      module.paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self,w, cr, width, height)
  end

  item.set_text = function (_,value)
    if data.disable_markup then
      tb4:set_text(value)
    else
      tb4:set_markup("<b>"..value.."</b>")
    end
    item._private_data.text = value
  end
  item:set_text(item.text or "")
  local tb2 = wibox.widget.textbox()
  tb2:set_text("alternate")
  tb2.fit = function(s,w,h)
    return w,h
  end

  vert:add(tb4)
  vert:add(tb2)

  -- Layout (align)
  local align = wibox.layout.align.horizontal()
  align:set_middle( vert   )
  align:set_left  ( layout )
  align:set_right ( right  )
  m:set_widget    ( align  )
  align._item = item
  align._data = data
--   align.fit   = data._internal.align_fit or align_fit
  item._internal.align = align

  -- Set widget
  item.widget = bg
  bg._item    = item

  -- Tooltip
  item.widget:set_tooltip(item.tooltip)

  -- Overlay
  item.set_overlay = function(_,value)
    item._private_data.overlay = value
    item.widget:emit_signal("widget::updated")
  end

  item._internal.text_w = wibox.widget.textbox()--tb4
  item._internal.icon_w = icon
  item._internal.margin_w = m

  -- Draw
  local item_style = item.style or data.item_style
  item_style(item,{})
  item.widget:set_fg(item._private_data.fg)

  -- Setup events
  module.setup_event(data,item)

  -- Setup dynamic underlay
    -- Setup dynamic underlay
  item:connect_signal("underlay::changed",function(_,udl)
    bg:emit_signal("widget::updated")
  end)

--   if item.buttons then
--     bg:buttons(item.buttons)
--   end

  return bg
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
