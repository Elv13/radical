local setmetatable = setmetatable
local math = math
local base = require( "radical.base" )
local color     = require( "gears.color"      )
local cairo     = require( "lgi"              ).cairo
local print = print

local module = {
  margins = {
    TOP    = 4,
    BOTTOM = 4,
    RIGHT  = 4,
    LEFT   = 4
  }
}

local focussed,default = nil, nil

local function gen(item_height,bg_color,border_color)
  local img = cairo.ImageSurface(cairo.Format.ARGB32, item_height,item_height)
  local cr = cairo.Context(img)
  local rad = corner_radius or 3
  cr:set_source(color(bg_color))
  cr:arc(rad,rad,rad,0,2*math.pi)
  cr:arc(item_height-rad,rad,rad,0,2*math.pi)
  cr:arc(rad,item_height-rad,rad,0,2*math.pi)
  cr:arc(item_height-rad,item_height-rad,rad,0,2*math.pi)
  cr:fill()
  cr:rectangle(0,rad, item_height, item_height-2*rad)
  cr:rectangle(rad,0, item_height-2*rad, item_height)
  cr:fill()
  return cairo.Pattern.create_for_surface(img)
end

local function draw(data,item,args)
  local args,flags = args or {},{}
  for _,v in pairs(args) do flags[v] = true end
  local ih = data.item_height
  if not focussed or not focussed[ih] then
    if not focussed then
      focussed,default={},{}
    end
    local bc = data.border_color
    focussed[ih] = gen(ih,data.bg_focus,bc)
    default [ih] = gen(ih,data.bg,bc)
  end

  if flags[base.item_flags.SELECTED] or (item._tmp_menu) then
    item.widget:set_bg(focussed[ih])
  else
      item.widget:set_bg(default[ih])
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
