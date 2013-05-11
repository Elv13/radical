local setmetatable = setmetatable
local context = require("radical.context")
local base    = require("radical.base")
local capi = { mouse = mouse, screen = screen }

local function set_position(data)
  local s = data.screen or capi.mouse.screen
  local geom = capi.screen[s].geometry
  data.wibox.x = geom.x + (geom.width/2) - data.width/2
  data.wibox.y = geom.y + (geom.height/2) - data.height/2
end

local function new(args)
  local args = args or {}
  args.internal = args.internal or {}
  args.arrow_type = base.arrow_type.NONE
  args.internal.set_position   = args.internal.set_position or set_position
  local ret = context(args)
  return ret
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
