local setmetatable = setmetatable
local color     = require( "gears.color"      )
local cairo     = require( "lgi"              ).cairo
local beautiful = require( "beautiful"        )
local print = print

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 0,
    LEFT   = 4
  }
}

local focussed,default,alt = nil, nil,{}

local function gen(item_height,bg_color,border_color)
  local img = cairo.ImageSurface(cairo.Format.ARGB32, 800,item_height)
  local cr = cairo.Context(img)
  cr:set_source( color(bg_color) )
  cr:paint()
  cr:set_source( color(border_color) )
  cr:rectangle(0,item_height-1,800,1)
  cr:fill()
  return cairo.Pattern.create_for_surface(img)
end

local function draw(data,item,is_focussed,is_pressed,col)
  local ih = data.item_height
  if not focussed or not focussed[ih] then
    if not focussed then
      focussed,default,alt={},{},{}
    end
    local bc = data.border_color
    focussed[ih] = gen(ih,data.bg_focus,bc)
    default [ih] = gen(ih,data.bg,bc)
  end
  if col and (not alt[col] or not alt[col][ih]) then
    alt[col] = alt[col] or {}
    alt[col][ih] = gen(ih,color(col),bc)
  end

  if is_focussed or (item._tmp_menu) then
    item.widget:set_bg(focussed[ih])
  elseif col then
    item.widget:set_bg(alt[col][ih])
  else
    item.widget:set_bg(default[ih])
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
