local setmetatable = setmetatable
local print        = print
local color        = require( "gears.color" )
local cairo        = require( "lgi"         ).cairo
local pango        = require( "lgi"         ).Pango
local pangocairo   = require( "lgi"         ).PangoCairo
local wibox        = require( "wibox"       )
local beautiful    = require( "beautiful"   )

local module = {}

local keys = {}

local pango_l,pango_crx,max_width,m_h = nil,nil,0,0
local function create_pango()
  local padding = beautiful.menu_height/5
  pango_crx = pangocairo.font_map_get_default():create_context()
  pango_l = pango.Layout.new(pango_crx)
  local desc = pango.FontDescription()
  desc:set_family("Verdana")
  desc:set_weight(pango.Weight.BOLD)
  desc:set_size((m_h-padding*2) * pango.SCALE)
  pango_l:set_font_description(desc)
  pango_l.text = "F88"
  max_width = pango_l:get_pixel_extents().width + m_h + 4
end

local function new(data,item)
  local pref = wibox.widget.textbox()
  local padding = beautiful.menu_height/5
  pref.draw = function(self,w, cr, width, height)
    local key = item._internal.f_key
    if m_h == 0 then
      m_h = height
      pref:emit_signal("widget::updated")
      create_pango()
      keys = {}
    end
    if key and key > 12 and keys[0] then
      cr:set_source_surface(keys[0])
      cr:paint()
    elseif not keys[key] then
      if not pango_l then
        m_h = height
        create_pango()
      end
      local img = cairo.ImageSurface(cairo.Format.ARGB32, max_width,beautiful.menu_height)
      local cr2 = cairo.Context(img)
      cr2:set_source(color(beautiful.fg_normal))
      cr2:arc((height-padding)/2 + 2, (height-padding)/2 + padding/2, (height-padding)/2,0,2*math.pi)
      cr2:arc(max_width - (height-padding)/2 - 2, (height-padding)/2 + padding/2, (height-padding)/2,0,2*math.pi)
      cr2:rectangle((height-padding)/2+2,padding/2,max_width - (height),(height-padding))
      cr2:fill()
      cr2:select_font_face("Arial", cairo.FontSlant.NORMAL, cairo.FontWeight.BOLD)
      cr2:set_font_size(height-padding*1.5)
      cr2:move_to(height/2 + padding/2,padding/4)
      cr2:set_source(color(beautiful.bg_normal))
      local text = (key and key <= 12) and ("F"..(key)) or " ---"
      pango_l.text = text
      cr2:show_layout(pango_l)
      if key > 12 then
        keys[0] = img
      else
        keys[key] = img
      end
    end
    if key and key > 12 and keys[0] then
      cr:set_source_surface(keys[0])
      cr:paint()
    else
      cr:set_source_surface(keys[key])
      cr:paint()
    end
  end
  pref.fit = function(self,width,height)
    return max_width,data.item_height
  end
  pref:set_markup("<span fgcolor='".. beautiful.bg_normal .."'><tt><b>F11</b></tt></span>")
  return pref
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
