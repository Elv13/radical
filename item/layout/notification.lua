local setmetatable = setmetatable
local wibox     = require( "wibox"                         )
local horizontal= require( "radical.item.layout.horizontal")
local margins2  = require( "radical.margins"               )
local common    = require( "radical.item.common"           )

local module = {}

-- Create the actual widget
local function create_item(item,data,args)
  -- Background
  local bg = wibox.container.background()

  -- Margins
  local m = wibox.container.margin()
  local mrgns = margins2(m,(item.item_style or data.item_style).margins)
  item.get_margins = function()
    return mrgns
  end

  -- Layout (left)
  local layout = wibox.layout.fixed.horizontal()
  bg:set_widget(m)

  -- Layout (right)
  local right = wibox.layout.fixed.horizontal()

  -- Icon
  local icon = common.setup_icon(item,data)
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
  local ck = horizontal:setup_checked(item,data)
  if ck then
    right:add(ck)
  end

  -- Sub_arrow
  local ar = horizontal:setup_sub_menu_arrow(item,data)
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
  tb2.fit = function(s,context,w,h)
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
  common.setup_event(data,item)

  return bg
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
