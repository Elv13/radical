local setmetatable = setmetatable
local color = require( "gears.color"   )
local theme = require( "radical.theme" )

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 0,
    LEFT   = 4
  }
}

local function horizontal(self, context, cr, width, height)
  if self._item and self._item.item_border_color then
    cr:set_source(color(self._item.item_border_color))
    cr:rectangle(0, height -1, width, 1)
    cr:fill()
  end
end

local function vertical(self, context, cr, width, height)
  if self._item and self._item.item_border_color then
    cr:set_source(color(self._item.item_border_color))
    cr:rectangle(width-1, 0, 1, height)
    cr:fill()
  end
end


local function draw(item, v)
  item.widget.border_color = color(item.item_border_color or item.border_color)
  item.widget.after_draw_children = v and vertical or horizontal

  theme.update_colors(item)
end

module.vertical = setmetatable({margins={
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 4,
    LEFT   = 4
  }},{ __call = function(_, item) draw(item,true) end }
)

return setmetatable(module, { __call = function(_, item) draw(item) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
