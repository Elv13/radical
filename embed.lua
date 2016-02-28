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
local common       = require( "radical.common"      )

local capi,module = { mouse = mouse , screen = screen , keygrabber = keygrabber },{}

local function setup_drawable(data)
  local internal = data._internal
  local private_data = internal.private_data

  -- An embeded menu can only be visible if the parent is
  data.get_visible = function() return data._embeded_parent and data._embeded_parent.visible or false end --Let the parent handle that
  data.set_visible = function(_,v) if data._embeded_parent then data._embeded_parent.visible = v end end

  -- Enumate geometry --BUG this is fake, but better than nothing

  if not data.layout then
    data.layout = layout.vertical
  end
  internal.layout = data.layout(data)
  data.margins={left=0,right=0,bottom=0,top=0}
  internal.layout:connect_signal("mouse::enter",function(_,geo)
    if data._embeded_parent._current_item then
      data._embeded_parent._current_item.selected = false
    end
  end)
  internal.layout:connect_signal("mouse::leave",function(_,geo)
    if data._current_item then
      data._current_item.selected = false
    end
  end)
end

local function new(args)
    local args = args or {}
    args.internal = args.internal or {}
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item or common.setup_item
    args.style = args.style or classic_style
    local ret = base(args)
    ret:connect_signal("clear::menu",function(_,vis)
      local l = ret._internal.content_layout or ret._internal.layout
      l:reset()
    end)
    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
