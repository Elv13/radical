local setmetatable = setmetatable
local beautiful = require( "beautiful"    )
local color     = require( "gears.color"  )
local cairo     = require( "lgi"          ).cairo
local wibox     = require( "wibox"        )
local checkbox  = require( "radical.widgets.checkbox" )
local fkey      = require( "radical.widgets.fkey"         )

local module = {}


-- Add [F1], [F2] ... to items
function module:setup_fkey(item,data)
  item._internal.set_map.f_key = function(value)
    item._internal.has_changed = true
    item._internal.f_key = value
    data:remove_key_hook("F"..value)
    data:add_key_hook({}, "F"..value      , "press", function()
      item.button1()
      data.visible = false
    end)
  end
  item._internal.get_map.f_key = function() return item._internal.f_key end
end

-- Like an overlay, but under
function module.paint_underlay(data,item,cr,width,height)
  cr:save()
  local udl = underlay.draw(item.underlay)
  cr:set_source_surface(udl,width-udl:get_width()-3)
  cr:paint_with_alpha(data.underlay_alpha)
  cr:restore()
end

-- Setup the item icon
function module:setup_icon(item,data)
  local icon = wibox.widget.imagebox()
  icon.fit = function(...)
    local w,h = wibox.widget.imagebox.fit(...)
    return w+3,h
  end
  if item.icon then
    icon:set_image(item.icon)
  end

  item._internal.set_map.icon = function (value)
    icon:set_image(value)
  end
  return icon
end

-- Show the checkbox
function module:setup_checked(item,data)
  if item.checkable then
    item._internal.get_map.checked = function()
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked()
      else
        return item._private_data.checked
      end
    end
    local ck = wibox.widget.imagebox()
    ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    item._internal.set_map.checked = function (value)
      item._private_data.checked = value
      ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
      item._internal.has_changed = true
    end
    return ck
  end
end

-- Use all the space, let "align_fit" compute the right size
local function textbox_fit(box,w,h)
  return w,h
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
  m:set_margins (0)
  m:set_left  ( (item.item_style or data.item_style).margins.LEFT   )
  m:set_right ( (item.item_style or data.item_style).margins.RIGHT  )
  m:set_top   ( (item.item_style or data.item_style).margins.TOP    )
  m:set_bottom( (item.item_style or data.item_style).margins.BOTTOM )

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
  layout:add(module:setup_icon(item,data))

  -- Prefix
  if args.prefix_widget then
    layout:add(args.prefix_widget)
  end

  -- Text
  local tb = wibox.widget.textbox()
  tb.fit = textbox_fit
  tb.draw = function(self,w, cr, width, height)
    if item.underlay then
      module.paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self,w, cr, width, height)
  end
  item.widget = bg
  tb:set_text(item.text)

  -- Checkbox
  local ck = module:setup_checked(item,data)
  if ck then
    right:add(ck)
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
  align.fit   = align_fit
  item._internal.align = align

  -- Tooltip
  item.widget:set_tooltip(item.tooltip)

  -- Draw
  local item_style = item.item_style or data.item_style
  item_style(data,item,{})
  item.widget:set_fg(item._private_data.fg)

  return bg
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
