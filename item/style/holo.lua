local setmetatable = setmetatable
local color = require( "gears.color"   )
local theme = require( "radical.theme" )

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 6,
    RIGHT  = 4,
    LEFT   = 4
  }
}

local default_height = 3

local function widget_draw(self, context, cr, width, height)
  -- Nothing to do
end

local function after_draw_children_top(self, context, cr, width, height)
  cr:save()
  cr:set_source(color(self._private.background))
  cr:rectangle(0, 0, width, default_height)
  cr:fill()
  cr:restore()
end

local function after_draw_children_bottom(self, context, cr, width, height)
  cr:save()
  cr:set_source(color(self._private.background))
  cr:rectangle(0, height -default_height, width, default_height)
  cr:fill()
  cr:restore()
end

local function draw(item,args)
  args = args or {}

  item.widget.draw = widget_draw
  item.widget.before_draw_children = args.pos == "top"
    and after_draw_children_top or after_draw_children_bottom

  theme.update_colors(item)
end

local function draw_top(item)
  return draw(item,{pos="top"})
end

-- Create an identical module for holo_top
module.top = setmetatable({
    draw = draw_top,
    margins = module.margins
  },
  {
    __call = function(_, ...) return draw_top(...) end
  }
)

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
