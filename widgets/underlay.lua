local type = type
local color = require("gears.color")
local gsurface = require("gears.surface")
local cairo = require("lgi").cairo
local pango = require("lgi").Pango
local pangocairo = require("lgi").PangoCairo
local beautiful = require("beautiful")

local module = {}

local pango_l,pango_crx = {},{}

function module.draw(text,args)
  local args = args or {}
  local padding = beautiful.default_height/3
  local height = args.height or (beautiful.menu_height)
  if not pango_l[height] then
    local pango_crx = pangocairo.font_map_get_default():create_context()
    pango_l[height] = pango.Layout.new(pango_crx)
    local desc = pango.FontDescription()
    desc:set_family("Verdana")
    desc:set_weight(pango.Weight.BOLD)
    desc:set_size((height-padding*2) * pango.SCALE)
    pango_l[height]:set_font_description(desc)
  end
  pango_l[height].text = text
  local width = pango_l[height]:get_pixel_extents().width + height + padding
  local img = cairo.ImageSurface.create(cairo.Format.ARGB32, width+(args.padding_right or 0), height+padding)
  cr = cairo.Context(img)
  cr:set_source(color(args.bg or beautiful.bg_alternate))
  cr:arc((height-padding)/2 + 2, (height-padding)/2 + padding/4 + (args.margins or 0), (height-padding)/2+(args.padding or 0)/2,0,2*math.pi)
  cr:fill()
  cr:arc(width - (height-padding)/2 - 2, (height-padding)/2 + padding/4 + (args.margins or 0), (height-padding)/2+(args.padding or 0)/2,0,2*math.pi)
  cr:rectangle((height-padding)/2+2,padding/4 + (args.margins or 0)-(args.padding or 0)/2,width - (height),(height-padding)+(args.padding or 0))
  cr:fill()
  cr:set_source(color(args.fg or beautiful.bg_normal))
  cr:set_operator(cairo.Operator.CLEAR)
  cr:move_to(height/2 + 2,padding/4 + (args.margins or 0)-(args.padding or 0)/2)
  cr:show_layout(pango_l[height])
  return img
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;