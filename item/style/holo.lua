local setmetatable = setmetatable
local math = math
local base = require( "radical.base" )
local color     = require( "gears.color"      )
local cairo     = require( "lgi"              ).cairo
local print = print

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 6,
    RIGHT  = 4,
    LEFT   = 4
  }
}

local state_cache = {}

local default_height = 3

local rect = {
  bottom = function(x,y,width,height) return 0, height-default_height, width , default_height end,
  top    = function(x,y,width,height) return 0,                     0, width , 3              end,
}

local function gen(width,height,bg_color,border_color, pos)
  local img = cairo.ImageSurface(cairo.Format.ARGB32, width,height)
  local cr = cairo.Context(img)
  cr:set_source(color(bg_color))
  cr:rectangle(rect[pos](0,0,width,height))
  cr:fill()
  return cairo.Pattern.create_for_surface(img)
end

local function widget_draw(self, w, cr, width, height)

  local state = self._item.state or {}
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
    cached = gen(width,height,self._item[state_name],bc,self.holo_pos)
    cache[hash] = cached
  end

  if current_state ~= self._last_state then
    self:set_bg(cached)
    self._last_state = current_state
  end

  self:_drawrounded(w, cr, width, height)
  local overlay = self._item and self._item.overlay
  if overlay then
    overlay(self._item._menu,self._item,cr,width,height)
  end
end

local function draw(item,args)
  local args = args or {}

  if not item.widget._overlay_init then
    item.widget._drawrounded = item.widget.draw
    item.widget.draw = widget_draw
    item.widget._overlay_init = true
    item.widget._item = item
    item.widget.holo_pos = args.pos or "bottom"
  end

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

local function draw_top(item,args)
  return draw(item,{pos="top"})
end

-- Create an identical module for holo_top
module.top = setmetatable({
    draw = draw_top,
    margins = module.margins
  },
  {
    __call = function(_, ...) return draw_top(...) end
  }
)

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
