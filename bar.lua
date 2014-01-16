local setmetatable,unpack = setmetatable,unpack
local base       = require( "radical.base"                 )
local color      = require( "gears.color"                  )
local wibox      = require( "wibox"                        )
local beautiful  = require( "beautiful"                    )
local cairo      = require( "lgi"                          ).cairo
local awful      = require( "awful"                        )
local util       = require( "awful.util"                   )
local fkey       = require( "radical.widgets.fkey"         )
local button     = require( "awful.button"                 )
local checkbox   = require( "radical.widgets.checkbox"     )
local item_style = require( "radical.item_style.arrow_prefix" )
local vertical   = require( "radical.layout.vertical"      )

local capi,module = { mouse = mouse , screen = screen, keygrabber = keygrabber },{}

local function get_direction(data)
  return "left" -- Nothing to do
end

local function set_position(self)
  return --Nothing to do
end

-- Draw the menu background
local function bg_draw(self, w, cr, width, height)
    cr:save()
    cr:set_source(color(self._data.bg))
    cr:rectangle(0,0,width,height)
    cr:fill()
    cr:restore()
  wibox.layout.margin.draw(self, w, cr, width, height)
end

local function setup_drawable(data)
  local internal = data._internal
  local get_map,set_map,private_data = internal.get_map,internal.set_map,internal.private_data

  --Init
  internal.margin = wibox.layout.margin()
  internal.margin._data = data
  internal.margin.draw = bg_draw

  internal.layout = wibox.layout.fixed.horizontal()
  internal.margin:set_widget(internal.layout)

  --Getters
  get_map.x         = function() return 0                                            end
  get_map.y         = function() return 0                                            end
  get_map.width     = function() return internal.margin.fix(internal.margin,9999,99) end
  get_map.height    = function() return beautiful.default_height                     end
  get_map.visible   = function() return true                                         end
  get_map.direction = function() return "left"                                       end
  get_map.margins   = function() return {left=0,right=0,top=0,bottom=0}              end

  -- This widget do not use wibox, so setup correct widget interface
  data.fit = internal.margin.fit
  data.draw = internal.margin.draw
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
  m:set_left  ( data.item_style.margins.LEFT   )
  m:set_right ( data.item_style.margins.RIGHT  )
  m:set_top   ( data.item_style.margins.TOP    )
  m:set_bottom( data.item_style.margins.BOTTOM )

  -- Layout (left)
  local layout = wibox.layout.fixed.horizontal()
  bg:set_widget(m)

  -- Layout (right)
  local right = wibox.layout.fixed.horizontal()

  -- F keys
  vertical:setup_fkey(item,data)
  if data.fkeys_prefix == true then
    layout:add(fkey(data,item))
  end

  -- Icon
  layout:add(vertical:setup_icon(item,data))

  -- Prefix
  if args.prefix_widget then
    layout:add(args.prefix_widget)
  end

  -- Text
  local tb = wibox.widget.textbox()
  tb.fit = textbox_fit
  tb.draw = function(self,w, cr, width, height)
    if item.underlay then
      vertical.paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self,w, cr, width, height)
  end
  item.widget = bg
  tb:set_text(item.text)

  -- Checkbox
  local ck = vertical:setup_checked(item,data)
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
  data.item_style(data,item,{})
  item.widget:set_fg(item._private_data.fg)

  return bg
end

local function setup_buttons(data,item,args)
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[#buttons+1] = button({},i,args["button"..i])
    end
  end

  -- Setup sub_menu
  if (item.sub_menu_m or item.sub_menu_f) and data.sub_menu_on >= base.sub_menu_on.BUTTON1 and data.sub_menu_on <= base.sub_menu_on.BUTTON3 then
    buttons[data.sub_menu_on] = item.widget:set_menu(item.sub_menu_m or item.sub_menu_f,data.sub_menu_on)
  end

  -- Scrool up
  if not buttons[4] then
    buttons[#buttons+1] = button({},4,function()
      data:scroll_up()
    end)
  end

  -- Scroll down
  if not buttons[5] then
    buttons[#buttons+1] = button({},5,function()
      data:scroll_down()
    end)
  end
  item.widget:buttons( util.table.join(unpack(buttons)))
end

local function setup_item(data,item,args)
  -- Add widgets
  data._internal.layout:add(create_item(item,data,args))
  item.widget:connect_signal("mouse::enter", function() item.selected = true end)
  item.widget:connect_signal("mouse::leave", function() item.selected = false end)

  -- Setup buttons
  setup_buttons(data,item,args)
end

local function new(args)
    local args = args or {}
    args.internal = args.internal or {}
    args.internal.get_direction  = args.internal.get_direction  or get_direction
    args.internal.set_position   = args.internal.set_position   or set_position
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item     or setup_item
--     args.style = args.style or arrow_style
    args.item_style = item_style
    args.sub_menu_on = base.sub_menu_on.BUTTON1
    local ret = base(args)
    ret:connect_signal("clear::menu",function(_,vis)
      ret._internal.layout:reset()
    end)
    ret:connect_signal("_hidden::changed",function(_,item)
      item.widget:emit_signal("widget::updated")
    end)
    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
