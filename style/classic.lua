local setmetatable = setmetatable
local base = require( "radical.base" )
local color     = require( "gears.color"      )

local module = {
  margins = {
    TOP    = 0 ,
    BOTTOM = 0 ,
    LEFT   = 0 ,
    RIGHT  = 0 ,
  }
}

local function draw(data)
  data.arrow_type = base.arrow_type.NONE
  if data.wibox then
    data.wibox.border_width = 1
    data.wibox.border_color = data.border_color
    data.wibox:set_bg(color(data.bg))
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
