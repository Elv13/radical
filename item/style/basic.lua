local setmetatable = setmetatable
local theme = require( "radical.theme" )

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 2,
    LEFT   = 4
  }
}

return setmetatable(module, { __call = function(_, ...) theme.update_colors(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
