local setmetatable = setmetatable
local print = print
local color = require("gears.color")
local cairo     = require( "lgi"              ).cairo
local wibox = require("wibox")

local beautiful    = require( "beautiful"    )

local module = {}

local function new(data,item)
  local pref = wibox.widget.textbox()
  pref.draw = function(self,w, cr, width, height)
    cr:set_source(color(beautiful.fg_normal))
    cr:arc((height-4)/2 + 2, (height-4)/2 + 2, (height-4)/2,0,2*math.pi)
    cr:arc(width - (height-4)/2 - 2, (height-4)/2 + 2, (height-4)/2,0,2*math.pi)
    cr:rectangle((height-4)/2+2,2,width - (height),(height-4))
    cr:fill()
    cr:select_font_face("Verdana", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
    cr:set_font_size(height-6)
    cr:move_to(height/2,height-4)
    cr:set_source(color(beautiful.bg_normal))
    local text = (item._internal.f_key and item._internal.f_key <= 12) and ("F"..(item._internal.f_key)) or "---"
    cr:show_text(text)
  end
  pref.fit = function(...)
    return 35,data.item_height
  end
  pref:set_markup("<span fgcolor='".. beautiful.bg_normal .."'><tt><b>F11</b></tt></span>")
  return pref
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
