local setmetatable = setmetatable
local beautiful = require( "beautiful"        )
local color     = require( "gears.color"      )
local cairo     = require( "lgi"              ).cairo
local base = require( "radical.base" )
local glib = require("lgi").GLib

local module = {
  margins = {
    BOTTOM = 10,
    TOP    = 10,
    LEFT   = 0 ,
    RIGHT  = 0 ,
  }
}

local function rotate(img, geometry, angle,swap_size)
  geometry = swap_size and {width = geometry.height, height=geometry.width} or geometry
  local matrix,pattern,img2 = cairo.Matrix(),cairo.Pattern.create_for_surface(img),cairo.ImageSurface(cairo.Format.ARGB32, geometry.width, geometry.height)
  cairo.Matrix.init_rotate(matrix,angle)
  matrix:translate((angle == math.pi/2) and 0 or -geometry.width, (angle == 3*(math.pi/2)) and 0 or -geometry.height)
  pattern:set_matrix(matrix)
  local cr2 = cairo.Context(img2)
  cr2:set_source(pattern)
  cr2:paint()
  return img2
end

local function do_gen_menu_top(data, width, height, radius,padding,args)
  local img = cairo.ImageSurface(cairo.Format.ARGB32, width,height)
  local cr = cairo.Context(img)
  local no_arrow = data.arrow_type == base.arrow_type.NONE
  local top_padding = (data.arrow_type == base.arrow_type.NONE) and 0 or 13
  local arrow_x = data._arrow_x or 20
  cr:set_operator(cairo.Operator.SOURCE)
  cr:set_source( color(args.bg) )
  cr:paint()
  cr:set_source( color(args.fg) )
  cr:rectangle(10, top_padding+padding, width - 20 +1 , 10)
  if not no_arrow then
    for i=1,13 do
      cr:rectangle((arrow_x) + 13  - i, i+padding , 2*i , 1)
    end
  end
  cr:rectangle(arrow_x+padding,top_padding+padding,26+padding,10)
  cr:rectangle(padding or 0,no_arrow and 10 or 23, width-2*padding, height-33 + (no_arrow and 13 or 0))
  cr:rectangle(10+padding-1,height-10, width-20, 10-padding)
  cr:fill()
  cr:arc(10,10+top_padding,(radius-padding),0,2*math.pi)
  cr:arc(width-10, 10+top_padding + (pdding or 0),(radius-padding),0,2*math.pi)
  cr:arc(10,height-(radius-padding)-padding,(radius-padding),0,2*math.pi)
  cr:arc(width-10,height-(radius-padding)-padding,(radius-padding),0,2*math.pi)
  cr:fill()
  return img
end

local function get_arrow_x(data,direction)
  local at = data.arrow_type
  local par_center_x = data.parent_geometry and (data.parent_geometry.x + data.parent_geometry.width/2) or -1
  local par_center_y = data.parent_geometry and (data.parent_geometry.y + data.parent_geometry.height/2) or -1
  local menu_beg_x = data.x
  local menu_end_x = data.x + data.width

  if at == base.arrow_type.PRETTY or not at then
    if direction == "left" then
      data._arrow_x = data.height -20 - (data.arrow_x or 20)
    elseif direction == "right" then
      --TODO
    elseif direction == "bottom" then
      data._arrow_x = data.width -20 - (data.arrow_x or 20)
      if par_center_x >= menu_beg_x then
        data._arrow_x = data.width - (par_center_x - menu_beg_x) - 13
      end
    elseif direction == "top" then
      --TODO
    end
  elseif at == base.arrow_type.CENTERED then
    data._arrow_x = data.width/2 - 13
  end
end

local function _set_direction(data,direction)
  get_arrow_x(data,direction)
  local geometry = (direction == "left" or direction == "right") and {width = data.height, height = data.width} or {height = data.height, width = data.width}
  local top_clip_surface        = do_gen_menu_top(data,geometry.width,geometry.height,10,data.border_width,{bg=beautiful.fg_normal or "#0000ff",fg=data.bg or "#00ffff"})
  local top_bounding_surface    = do_gen_menu_top(data,geometry.width,geometry.height,10,0,{bg="#00000000",fg="#ffffffff"})

  local arr_margin,angle,mar_func = (data.arrow_type == base.arrow_type.NONE) and 0 or 13,0
  if direction == "bottom" then
    angle,swap = math.pi,false
  elseif direction == "left" then
    angle,swap = math.pi/2,true
  elseif direction == "right" then
    angle,swap = 3*math.pi/2,true
  end
  if angle ~= 0 then
    top_bounding_surface = rotate(top_bounding_surface,geometry,angle,swap)
    top_clip_surface     = rotate(top_clip_surface,geometry,angle,swap)
  end
  data.wibox.shape_bounding = top_bounding_surface._native
  data.wibox:set_bg(cairo.Pattern.create_for_surface(top_clip_surface))
  data._internal._need_direction_reload = false
end

-- Try to avoid useless repaint, this function is heavy
local function set_direction(data,direction)
  data._internal._need_direction = direction
  if not data._internal._need_direction_reload then
    glib.idle_add(glib.PRIORITY_HIGH_IDLE, function() _set_direction(data,data._internal._need_direction) end)
    data._internal._need_direction_reload = true
  end
end

local function draw(data,args)
  local args = args or {}
  local direction = data.direction or "top"

  set_direction(data,direction)
--   data._internal.set_position(data) --TODO DEAD CODE?

  local margins = data.margins
  local margin = data._internal.margin
  for k,v in pairs(margins) do
    margin["set_"..k](margin,v)
  end
  return w,w2
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
