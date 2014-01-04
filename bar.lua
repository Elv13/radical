local base = require( "radical.base" )
local print = print
local unpack = unpack
local setmetatable = setmetatable
local color     = require( "gears.color"      )
local wibox     = require( "wibox"            )
local beautiful = require( "beautiful"        )
local cairo     = require( "lgi"              ).cairo
local awful     = require( "awful"            )
local util      = require( "awful.util"       )
local button    = require( "awful.button"     )
local checkbox  = require( "radical.widgets.checkbox" )
local item_style   = require( "radical.item_style.arrow_alt" )

local capi,module = { mouse = mouse , screen = screen, keygrabber = keygrabber },{}

local function get_direction(data)
  return "left" -- Nothing to do
end

local function set_position(self)
  return --Nothing to do
end

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

  internal.layout = wibox.layout.fixed.horizontal() --data.layout(data) --TODO fix
  internal.margin:set_widget(internal.layout)

  --Getters
  get_map.wibox     = function() return nil end -- Will this break?
  get_map.x         = function() return 0 end
  get_map.y         = function() return 0 end
  get_map.width     = function() return 500 end
  get_map.height    = function() return 40 end
  get_map.visible   = function() return private_data.visible end
  get_map.direction = function() return private_data.direction end
  get_map.margins   = function()
    local ret = {left=data.border_width,right=data.border_width,top=data.style.margins.TOP,bottom=data.style.margins.BOTTOM}
    if data.arrow_type ~= base.arrow_type.NONE then
      ret[data.direction] = ret[data.direction]+13
    end
    return ret
  end

  --Setters
  function internal:set_visible(value)
    -- TODO
  end

--   if data.visible then
--     local fit_w,fit_h = data._internal.layout:fit()
--     data.width = fit_w
--     data.height = fit_h
--   end
  
  -- This widget do not use wibox, so setup correct widget interface
  data.fit = internal.margin.fit
  data.draw = internal.margin.draw
end

local function create_item(item,data)
  -- Background
  local bg = wibox.widget.background()

  -- Margins
  local m = wibox.layout.margin(la)
  m:set_margins (0)
  m:set_left  ( data.item_style.margins.LEFT   )
  m:set_right ( data.item_style.margins.RIGHT  )
  m:set_top   ( data.item_style.margins.TOP    )
  m:set_bottom( data.item_style.margins.BOTTOM )

  -- Layout
  local layout = wibox.layout.fixed.horizontal()
  bg:set_widget(m)
  m:set_widget(layout)

  -- Content
  local tb = wibox.widget.textbox()
  layout:add(tb)
  item.widget = bg
  tb:set_text("bob")

  -- Draw
  data.item_style(data,item,false,false)
  item.widget:set_fg(item._private_data.fg)

  return bg
end

local function setup_item(data,item,args)

  -- Add widgets
  data._internal.layout:add(create_item(item,data))
  item.widget:connect_signal("mouse::enter", function() item.selected = true end)
  item.widget:connect_signal("mouse::leave", function() item.selected = false end)

  -- Setup buttons
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
  if not buttons[4] then
    buttons[#buttons+1] = button({},4,function()
      data:scroll_up()
    end)
  end
  if not buttons[5] then
    buttons[#buttons+1] = button({},5,function()
      data:scroll_down()
    end)
  end
  item.widget:buttons( util.table.join(unpack(buttons)))
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
