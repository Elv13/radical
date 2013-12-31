local base = require( "radical.base" )
local print = print
local unpack = unpack
local debug = debug
local type = type
local setmetatable = setmetatable
local color     = require( "gears.color"      )
local wibox     = require( "wibox"            )
local beautiful = require( "beautiful"        )
local cairo     = require( "lgi"              ).cairo
local awful     = require( "awful"            )
local util      = require( "awful.util"       )
local button    = require( "awful.button"     )
local layout    = require( "radical.layout"   )
local checkbox  = require( "radical.widgets.checkbox" )
local classic_style = require( "radical.style.classic" )

local capi,module = { mouse = mouse , screen = screen , keygrabber = keygrabber },{}

local function setup_drawable(data)
  local internal = data._internal
  local get_map,set_map,private_data = internal.get_map,internal.set_map,internal.private_data
  get_map.visible = function() return true end --Let the parent handle that
  set_map.visible = function(v) if data._embeded_parent then data._embeded_parent.visible = v end end
  if not data.layout then
    data.layout = layout.vertical
  end
  internal.layout = data.layout(data)
  data.width,data.height = data._internal.layout:fit()
end

local function setup_item(data,item,args)
  local f = (data._internal.layout.setup_item) or (layout.vertical.setup_item)
  f(data._internal.layout,data,item,args)
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
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item or setup_item
    args.style = args.style or classic_style
    local ret = base(args)
    ret:connect_signal("clear::menu",function(_,vis)
      local l = ret._internal.content_layout or ret._internal.layout
      l:reset()
    end)
    ret:connect_signal("_hidden::changed",function(_,item)
      item.widget:emit_signal("widget::updated")
    end)
    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;