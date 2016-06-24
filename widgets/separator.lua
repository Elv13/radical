local setmetatable = setmetatable
local color     = require( "gears.color")
local wibox     = require( "wibox"      )
local beautiful = require( "beautiful"  )

local module = {HORIZONTAL=1,VERTICAL=2}

local function draw(self, context, cr, width, height)
  cr:save()
  cr:set_source(self._color)
  if self.direction == module.VERTICAL then
    cr:rectangle(2,2,1,height-4)
  else
    cr:rectangle(5,2,width-10,1)
  end
  cr:fill()
  cr:restore()
end

local function fit(box, context, w, h)
  local direction = box.direction or w > h and module.HORIZONTAL or module.VERTICAL
  return direction == module.VERTICAL and 5 or w,direction == module.VERTICAL and h or 5
end

local function new(menu,direction)
  local bg = wibox.widget.base.make_widget()
  bg.direction = direction or module.HORIZONTAL
  bg.fit = fit
  bg._color = color( menu and menu.separator_color or beautiful.menu_border_color or beautiful.menu_fg or beautiful.fg_normal)
  bg.draw = draw
  bg._force_fit = true
  return bg
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
