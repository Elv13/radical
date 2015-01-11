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

local state_cache = {}

local function rect(cr,width,height,x,y)
  local radius = 3
  cr:move_to(0,radius)
  cr:arc(radius,radius,radius,math.pi,3*(math.pi/2))
  cr:arc(width-radius,radius,radius,3*(math.pi/2),math.pi*2)
  cr:arc(width-radius,height-radius,radius,math.pi*2,math.pi/2)
  cr:arc(radius,height-radius,radius,math.pi/2,math.pi)
  cr:close_path()
end

local function gen(width,height,bg_color,border_color,item,shadow)
  local extra = shadow and 5 or 0
  local img = cairo.ImageSurface(cairo.Format.ARGB32, width+extra,height+extra)
  local cr = cairo.Context(img)

  rect(cr,width,height,0,0)

  cr:set_source(color(bg_color))
  if item.item_border_color then
    cr:fill_preserve()
    cr:set_line_width(item.border_width or 1)
    cr:set_source(color(item.item_border_color))
    cr:stroke()
  else
    cr:fill()
  end
  return cairo.Pattern.create_for_surface(img)
end

local function widget_draw(self, w, cr, width, height,shadow)
  local item = self._item
  local state = item.state or {}
  local current_state = state._current_key or ""
  if not state_cache[current_state] then
    state_cache[current_state] = {}
  end
  local cache = state_cache[current_state]
  local hash = width+1234*height

  local cached = cache[hash]

  --Generate the pixmap
  if not cached then
    local state_name = current_state == "" and "bg" or "bg_"..(base.colors_by_id[current_state] or "")
    cached = gen(width,height,item[state_name],bc,item,shadow)
    cache[hash] = cached
  end

  if current_state ~= self._last_state then
    self:set_bg(cached)
    self._last_state = current_state
  end

  self:_drawrounded(w, cr, width, height)
  local overlay = item and item.overlay
  if overlay then
    overlay(item._menu,item,cr,width,height)
  end
end

local function draw_width_shadow(self, w, cr, width, height)

  cr:save()
  cr:reset_clip()
  cr:set_source_rgba(0,0,0,.1)
  cr:set_line_width(1)
  cr:translate(3,3)
  for i=1,3 do
    cr:translate(-1,-1)
    rect(cr,width,height)
    cr:fill()
  end
  cr:restore()

  widget_draw(self, w, cr, width, height,true)
end

local function common(item,args)
  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = base.colors_by_id[current_state]

  if current_state == base.item_flags.SELECTED or (item._tmp_menu) then
    item.widget:set_fg(item["fg_focus"])
  elseif state_name then
    item.widget:set_fg(              item["fg_"..state_name])
  else
    item.widget:set_fg(item["fg_normal"])
  end
end

local function draw(item,args)
  local args = args or {}

  if not item.widget._overlay_init then
    item.widget._drawrounded = item.widget.draw
    item.widget.draw = widget_draw
    item.widget._overlay_init = true
    item.widget._item = item
  end

  common(item,args)
end

-- Same as the default, but also draw a shadow
local function shadow(item,args)
  local args = args or {}

  if not item.widget._overlay_init then
    item.widget._drawrounded = item.widget.draw
    item.widget.draw = draw_width_shadow
    item.widget._overlay_init = true
    item.widget._item = item
  end

  common(item,args)
end
module.shadow = {}
setmetatable(module.shadow, { __call = function(_, ...) return shadow(...) end })

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
