local setmetatable = setmetatable
local beautiful = require( "beautiful"     )
local color     = require( "gears.color"   )
local cairo     = require( "lgi"           ).cairo
local theme     = require( "radical.theme" )

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 2,
    LEFT   = 4
  }
}

local function after_draw_children(self, context, cr, width, height)
  cr:set_source(self.col1)
  cr:rectangle(0,3,1,height-6)
  cr:fill()
  cr:set_source(self.col2)
  cr:rectangle(width-1,3,1,height-6)
  cr:fill()
end

local function draw(item)
  if not item.widget._overlay_init then
    item.widget.after_draw_children = after_draw_children
    item.widget._overlay_init = true

    -- Build the 2 item border colors, this item_style doesn't support gradient
    -- or patterns
    item.widget.col1 = color(item.item_border_color or item.border_color or beautiful.border_color)
    local _,r,g,b,a = item.widget.col1:get_rgba()
    r,g,b = r-.2,g-.2,b-.2
    item.widget.col2 = cairo.Pattern.create_rgba(r,g,b,a)
  end

  theme.update_colors(item)
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
