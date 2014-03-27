local setmetatable = setmetatable
local base      = require( "radical.base"     )
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

local function widget_draw(self, w, cr, width, height)
  self:_draw2(w, cr, width, height)
  local overlay = self._item and self._item.overlay
  if overlay then
    overlay(self._item._menu,self._item,cr,width,height)
  end
end

local function draw(item,args)
  local args = args or {}
  local col = args.color

  if not item.widget._overlay_init then
    item.widget._draw2 = item.widget.draw
    item.widget.draw = widget_draw
    item.widget._overlay_init = true
  end

  local ih = item.height or 1
  if not focussed or not focussed[ih] then
    if not focussed then
      focussed,default,alt={},{},{}
    end
    local bc = item.border_color
    focussed[ih] = gen(ih,item.bg_focus,bc)
    default [ih] = gen(ih,item.bg,bc)
  end
  if col and (not alt[col] or not alt[col][ih]) then
    alt[col] = alt[col] or {}
    alt[col][ih] = gen(ih,color(col),bc)
  end

  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = base.colors_by_id[current_state]

  if current_state  == base.item_flags.SELECTED or (item._tmp_menu) then
    item.widget:set_bg(focussed[ih])
    item.widget:set_fg(item["fg_focus"])
  elseif col then
    item.widget:set_bg(alt[col][ih])
    item.widget:set_fg(item["fg_"..state_name])
  else
    item.widget:set_bg(default[ih])
    item.widget:set_fg(item["fg"])
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
