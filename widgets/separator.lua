local setmetatable = setmetatable
local print = print
local color     = require( "gears.color")
local cairo     = require( "lgi"        ).cairo
local wibox     = require( "wibox"      )
local beautiful = require( "beautiful"  )

local function draw(self, w, cr, width, height)
  cr:save()
  cr:set_source(self._color)
  cr:rectangle(5,2,width-10,1)
  cr:fill()
  cr:restore()
end

local function fit(box, w, h)
  return w,5
end

local function new(menu)
  local bg = wibox.widget.base.make_widget()
  bg.fit = fit
  bg._color = color( menu and menu.separator_color or beautiful.border_color or beautiful.fg_normal)
  bg.draw = draw
  bg._force_fit = true
  return bg
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
