local setmetatable = setmetatable
local theme     = require( "radical.theme" )
local shape     = require( "gears.shape"   )

local module = {
  margins = {
    TOP    = 0,
    BOTTOM = 0,
    RIGHT  = 15,
    LEFT   = 15
  }
}

local function draw(item)
  item.widget:set_shape(shape.hexagon)
  item.widget:set_shape_border_width(item.border_width)
  theme.update_colors(item)
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
