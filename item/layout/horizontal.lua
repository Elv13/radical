local setmetatable = setmetatable
local beautiful = require( "beautiful"    )
local color     = require( "gears.color"  )
local cairo     = require( "lgi"          ).cairo
local wibox     = require( "wibox"        )
local checkbox  = require( "radical.widgets.checkbox"  )
local fkey      = require( "radical.widgets.fkey"      )
local underlay  = require( "radical.widgets.underlay"  )
local theme     = require( "radical.theme"             )
local util      = require( "awful.util"                )
local margins2  = require( "radical.margins")
local shape     = require( "gears.shape"   )
local surface   = require( "gears.surface" )

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
function module.paint_underlay(data,item,cr,width,height, name)
  name = name or "underlay"
  cr:save()
  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = theme.colors_by_id[current_state] or ""

  local bg_color = item[name.."_bg_"..state_name] or data[name.."_bg_"..state_name] or data[name.."_bg"]
  local style    = item[name.."_style"          ] or data[name.."_style"          ]
  local alpha    = item[name.."_alpha"          ] or data[name.."_alpha"          ]
  local align    = item[name.."_align"          ] or data[name.."_align"          ]

  local udl = underlay.draw(item[name],{style=data.underlay_style,height=height,bg=bg_color, style = style})

  if align == "center" then
    local offset = (width-udl:get_width()-6)/2
    cr:set_source_surface(udl,3 + offset)
  else
    cr:set_source_surface(udl,width-udl:get_width()-3)
  end
  cr:paint_with_alpha(data[name.."_alpha"])
  cr:restore()
end

function module.after_draw_children(self, context, cr, width, height)
  if self._item.overlay then
    module.paint_underlay(self._data, self._item, cr, width, height, "overlay")
  end

  if self._item.overlay_draw then
    self._item.overlay_draw(context,self._item,cr,width,height)
  end

  -- Draw the border, if any
  if self._after_draw_children then
    self._after_draw_children(self, context, cr, width, height)
  end
end

-- Apply icon transformation
function module.set_icon(self,image)
  if self._data.icon_transformation then
    self._item._original_icon = image
    image = self._data.icon_transformation(image,self._data,self._item)
  end
  wibox.widget.imagebox.set_image(self,image)
end

-- Setup the item icon
function module:setup_icon(item,data)
  local icon = wibox.widget.imagebox()
  icon._data = data
  icon._item = item
  icon.set_image = module.set_icon
  if item.icon then
    icon:set_image(item.icon)
  end

  item.set_icon = function (_,value)
    icon:set_image(value)
  end
  return icon
end

-- Show the checkbox
function module:setup_checked(item,data)
  if item.checkable then
    item.get_checked = function()
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked(data,item)
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
  if (item._private_data.sub_menu_f or item._private_data.sub_menu_m) and not data.disable_submenu_icon then
    if not sub_arrow then
      sub_arrow = wibox.widget.imagebox() --TODO, make global
      sub_arrow.fit = function(box, context,w, h) return (sub_arrow._image and sub_arrow._image:get_width() or 0),item.height end

      if beautiful.menu_submenu_icon then
        sub_arrow:set_image( beautiful.menu_submenu_icon   )
      else
        local h = data.item_height
        sub_arrow:set_image(surface.load_from_shape(7, h,
          shape.transform(shape.isosceles_triangle) : rotate_at(3.5,h/2,math.pi/2),
          beautiful.menu_fg_normal or beautiful.menu_fg or beautiful.fg_normal
        ))
      end
    end
    return sub_arrow
  end
end

-- Proxy all events to the parent
function module.setup_event(data,item,widget)
  local widget = widget or item.widget

  -- Setup data signals
  widget:connect_signal("button::press",function(_,__,___,id,mod,geo)
    local mods_invert = {}
    for k,v in ipairs(mod) do
      mods_invert[v] = i
    end

    item.state[4] =  true
    data:emit_signal("button::press",item,id,mods_invert,geo)
    item:emit_signal("button::press",data,id,mods_invert,geo)
  end)
  widget:connect_signal("button::release",function(wdg,__,___,id,mod,geo)
    local mods_invert = {}
    for k,v in ipairs(mod) do
      mods_invert[v] = i
    end
    item.state[4] =  nil
    data:emit_signal("button::release",item,id,mods_invert,geo)
    item:emit_signal("button::release",data,id,mods_invert,geo)
  end)
  widget:connect_signal("mouse::enter",function(b,mod,geo)
    data:emit_signal("mouse::enter",item,mod,geo)
    item:emit_signal("mouse::enter",data,mod,geo)
  end)
  widget:connect_signal("mouse::leave",function(b,mod,geo)
    data:emit_signal("mouse::leave",item,mod,geo)
    item:emit_signal("mouse::leave",data,mod,geo)
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
local function textbox_fit(box,context,w,h)
  return w,h
end

-- Force the width or compute the minimum space
local function align_fit(box,context,w,h)
  local mar = util.table.join(box._data.item_style.margins,box._data.default_item_margins)
  if box._item.width then return box._item.width - box._data.item_style.margins.LEFT - box._data.item_style.margins.RIGHT,h end
  return box.first:fit(context,w,h)+wibox.widget.textbox.fit(box.second,context,w,h)+box.third:fit(context,w,h),h
end

-- Create the actual widget
local function create_item(item,data,args)
  -- Background
  local bg = wibox.widget.background()

  -- Margins
  local m = wibox.layout.margin(la)
--   print("LA",data.default_item_margins.TOP)
  local mrgns = margins2(m,util.table.join((item.item_style or data.item_style).margins,data.default_item_margins))
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
  local icon = module:setup_icon(item,data)
  icon.fit = function(...)
    local w,h = wibox.widget.imagebox.fit(...)
    return w+3,h
  end
  layout:add(icon)
  if data.icon_per_state == true then
    item:connect_signal("state::changed",function(i,d,st)
      if item._original_icon and data.icon_transformation then
        wibox.widget.imagebox.set_image(icon,data.icon_transformation(item._original_icon,data,item))
      end
    end)
  end

  -- Prefix
  if args.prefix_widget then
    layout:add(args.prefix_widget)
  end

  -- Text
  local tb = wibox.widget.textbox()
  tb.fit = data._internal.text_fit or textbox_fit
  tb.draw = function(self, context, cr, width, height)
    if item.underlay then
      module.paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self, context, cr, width, height)
  end
  tb:set_text(item.text)
  item.set_text = function (_,value)
    if data.disable_markup then
      tb:set_text(value)
    else
      tb:set_markup(value)
    end
    item._private_data.text = value
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

  -- Layout (align)
  local align = wibox.layout.align.horizontal()
  align:set_middle( tb     )
  align:set_left  ( layout )
  align:set_right ( right  )
  m:set_widget    ( align  )
  align._item = item
  align._data = data
  align.fit   = data._internal.align_fit or align_fit
  item._internal.align = align

  -- Set widget
  item.widget = bg
  bg._item    = item
  bg._data    = data

  -- Tooltip
  item.widget:set_tooltip(item.tooltip)

  -- Overlay
  item.set_overlay = function(_,value)
    item._private_data.overlay = value
    item.widget:emit_signal("widget::updated")
  end

  item._internal.text_w = tb
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

  bg._after_draw_children = bg.after_draw_children
  bg.after_draw_children  = module.after_draw_children

  return bg
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
