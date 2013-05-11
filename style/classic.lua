local setmetatable = setmetatable
local base = require( "radical.base" )

local module = {
  margins = {
    TOP    = 0 ,
    BOTTOM = 0 ,
    LEFT   = 0 ,
    BOTTOM = 0 ,
  }
}

local function draw(data)
  data.arrow_type = base.arrow_type.NONE
  data.wibox.border_width = 1
  data.wibox.border_color = data.border_color
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
