local setmetatable = setmetatable
local theme = require( "radical.theme" )
local shape = require( "gears.shape"   )
local color = require( "gears.color"   )

local module = {
  margins = {
    TOP    = 4,
    BOTTOM = 4,
    RIGHT  = 4,
    LEFT   = 4
  }
}

local function widget_draw(self, context, cr, width, height)

  if not self._private.background then
    cr:set_source_rgba(0,0,0,0)
  else
    cr:set_source(color(self._private.background))
  end

  shape.rounded_rect(cr ,width, height, 3)

  if self._item.item_border_color then
    cr:fill_preserve()
    cr:set_line_width(self._item.border_width or 1)
    cr:set_source(color(self._item.item_border_color))
    cr:stroke()
  else
    cr:fill()
  end

end

local function draw_width_shadow(self, context, cr, width, height)
  if not self._private.background then return end

  cr:save()
  cr:reset_clip()
  cr:set_source_rgba(0,0,0,.1)
  cr:set_line_width(1)
  cr:translate(3,3)
  for i=1,3 do
    cr:translate(-1,-1)
    shape.rounded_rect(cr, width, height, 3)
    cr:fill()
  end
  cr:restore()
end

local function draw(item)
  item.widget._item = item
  item.widget.draw = widget_draw
  theme.update_colors(item)
end

-- Same as the default, but also draw a shadow
local function shadow(item)
  item.widget.draw = widget_draw
  item.widget.before_draw_children = draw_width_shadow
  theme.update_colors(item)
end

module.shadow = {need_full_repaint = true}
setmetatable(module.shadow, { __call = function(_, ...) return shadow(...) end })

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
