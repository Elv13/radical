local setmetatable = setmetatable
local context   = require( "radical.context" )
local base      = require( "radical.base"    )
local shape     = require( "gears.shape"     )
local placement = require( "awful.placement" )

local function new(args)
  args = args or {}
  args.internal = args.internal or {}
  args.arrow_type = base.arrow_type.NONE

  local ret = context(args)

  local w = ret.wibox

  w:set_shape (shape.rounded_rect, 10)

  w.placement = placement.centered

  if args.screen then
    w.screen = args.screen
  end

  local s = w.screen
  w:connect_signal("property::geometry", function()
    if w.screen ~= s then
      w:move_by_parent()
    end
  end)

  return ret
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
