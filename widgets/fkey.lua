local setmetatable = setmetatable
local print        = print
local color        = require( "gears.color" )
local cairo        = require( "lgi"         ).cairo
local pango        = require( "lgi"         ).Pango
local pangocairo   = require( "lgi"         ).PangoCairo
local wibox        = require( "wibox"       )
local beautiful    = require( "beautiful"   )

local pango_l,pango_crx,max_width,keys = nil,nil,0,{}

local function create_pango(height)
  local padding = height/4
  pango_crx = pangocairo.font_map_get_default():create_context()
  pango_l = pango.Layout.new(pango_crx)
  local desc = pango.FontDescription()
  desc:set_family("Verdana")
  desc:set_weight(pango.Weight.BOLD)
  desc:set_size((height-padding*2) * pango.SCALE)
  pango_l:set_font_description(desc)
  pango_l.text = "F88"
  max_width = pango_l:get_pixel_extents().width + height + 4
end

local function new(data,item)
  local pref = wibox.widget.textbox()
  pref.draw = function(self,w, cr, width, height)
    local padding = height/4
    local key = item._internal.f_key
    if not keys[height]  then
      pref:emit_signal("widget::updated")
      create_pango(height)
      keys[height] = {}
    end
    if key and key > 12 and keys[height][0] then
      cr:set_source_surface(keys[height][0])
      cr:paint()
    elseif not keys[height] or not keys[height][key] then
      if not pango_l then
        create_pango(height)
      end
      local img = cairo.ImageSurface(cairo.Format.ARGB32, max_width,beautiful.menu_height)
      local cr2 = cairo.Context(img)
      cr2:set_source(color(beautiful.fg_normal))
      cr2:arc((height-padding)/2 + 2, (height-padding)/2 + padding/2, (height-padding)/2,0,2*math.pi)
      cr2:arc(max_width - (height-padding)/2 - 2, (height-padding)/2 + padding/2, (height-padding)/2,0,2*math.pi)
      cr2:rectangle((height-padding)/2+2,padding/2,max_width - (height),(height-padding))
      cr2:fill()
      cr2:move_to(height/2 + padding/2,padding/4)
      cr2:set_source(color(beautiful.bg_normal))
      pango_l.text = (key and key <= 12) and ("F"..(key)) or " ---"
      cr2:show_layout(pango_l)
      keys[height][key > 12 and 0 or key] = img
    end
    cr:set_source_surface((key and key > 12 and keys[height][0]) and keys[height][0] or keys[height][key])
    cr:paint()
  end
  pref.fit = function(self,width,height)
    return max_width,data.item_height
  end
  pref:set_markup("<span fgcolor='".. beautiful.bg_normal .."'><tt><b>F11</b></tt></span>")
  return pref
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
