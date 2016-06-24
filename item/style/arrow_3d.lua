local setmetatable = setmetatable
local color  = require( "gears.color"  )
local theme     = require( "radical.theme" )

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 2,
    LEFT   = 4
  },
  need_full_repaint = true
}

local function create_path(cr,x,height,padding)
  local p2 = padding*2
  cr:move_to(x-(height-p2)/2,padding)
  cr:line_to(x+0,(height-p2)/2)
  cr:line_to(x-(height-p2)/2,(height-p2))
end


local c1 = color("#474e56dd")
local c2 = color("#5b646cdd")
local c3 = color("#212429dd")
local c4 = color("#3b4249dd")

local function widget_draw23(self, context, cr, width, height)
  cr:save()
  cr:reset_clip()
  cr:set_line_width(1)
  -- Step 1: Paint the background
  create_path(cr,0,height,0)
  cr:line_to(width-(height)/2,(height))
  cr:line_to(width,(height)/2)
  cr:line_to(width-(height)/2,0)
  cr:close_path()
  cr:set_source(self.radical_bg)
  cr:fill()

  -- Step 2: Paint the border
  cr:set_source(c1)
  create_path(cr,-2,height,1)
  cr:stroke()

  cr:set_source(c2)
  create_path(cr,-1,height,1)
  cr:stroke()

  cr:set_source(c3)
  create_path(cr,0,height,1)
  cr:stroke()

  cr:set_source(c4)
  create_path(cr,1,height,1)
  cr:stroke()
  cr:restore()

  if self.__drawbasic then
    self.__drawbasic(self, context, cr, width, height)
  end
end

local function new_set_bg(self,bg)
  self.radical_bg = color(bg)
end

local function draw(item)
  if not item.widget._overlay_init and not item.widget._draw then
    item.widget.__drawbasic = item.widget.draw
    item.widget.draw = widget_draw23
    item.widget._overlay_init = true
    item.widget.set_bg = new_set_bg
    item.widget.background = nil
  end

  theme.update_colors(item)
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
