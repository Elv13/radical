local setmetatable = setmetatable
local beautiful = require( "beautiful"        )
local color     = require( "gears.color"      )
local cairo     = require( "lgi"              ).cairo
local base = require( "radical.base" )
local glib = require("lgi").GLib
local margins = require("radical.margins")

local module = {
  margins = {
    BOTTOM = 10,
    TOP    = 10,
    LEFT   = 0 ,
    RIGHT  = 0 ,
  }
}

-- Constants
local radius       = 10
local arrow_height = 13

-- Matrix rotation per direction
local angles = {
  top    = 0           , -- 0
  bottom = math.pi     , -- 180
  right  = 3*math.pi/2 , -- 270
  left   = math.pi/2   , -- 90
}

-- If width and height need to be swapped
local swaps = {
  top   =  false,
  bottom=  false,
  right =  true ,
  left  =  true ,
}

local function rotate(img, geometry, angle,swap_size)
  -- Swap height ans width
  geometry = swap_size and {width = geometry.height, height=geometry.width} or geometry

  -- Create a rotation matrix
  local matrix,pattern,img2 = cairo.Matrix(),cairo.Pattern.create_for_surface(img),cairo.ImageSurface(cairo.Format.ARGB32, geometry.width, geometry.height)
  cairo.Matrix.init_rotate(matrix,angle)

  -- Apply necessary transformations
  matrix:translate((angle == math.pi/2) and 0 or -geometry.width, (angle == 3*(math.pi/2)) and 0 or -geometry.height)
  pattern:set_matrix(matrix)

  -- Paint the new image
  local cr2 = cairo.Context(img2)
  cr2:set_source(pattern)
  cr2:paint()
  return img2
end

-- Generate a rounded cairo path with the arrow
local function draw_roundedrect_path(cr, data, width, height, radius,padding)
  local no_arrow    = data.arrow_type == base.arrow_type.NONE
  local top_padding = (no_arrow) and 0 or arrow_height
  local arrow_x     = data._arrow_x or 20

  --Begin the rounded rect
  cr:move_to(padding,radius)
  cr:arc(radius      , radius+top_padding               , (radius-padding) , math.pi       , 3*(math.pi/2))

  -- Draw the arrow
  if not no_arrow then
    cr:line_to(arrow_x                , top_padding+padding)
    cr:line_to(arrow_x+arrow_height   , padding            )
    cr:line_to(arrow_x+2*arrow_height , top_padding+padding)
  end

  -- Complete the rounded rect
  cr:arc(width-radius, radius+top_padding               , (radius-padding) , 3*(math.pi/2) , math.pi*2   )
  cr:arc(width-radius, height-(radius-padding)-padding  , (radius-padding) , math.pi*2     , math.pi/2   )
  cr:arc(radius      , height-(radius-padding)-padding  , (radius-padding) , math.pi/2     , math.pi     )
  cr:close_path()
end

local function do_gen_menu_top(data, width, height, radius,padding,args)
  local img = cairo.ImageSurface(cairo.Format.ARGB32, width,height)
  local cr = cairo.Context(img)

  -- Clear the surface
  cr:set_operator(cairo.Operator.SOURCE)
  cr:set_source( color(args.bg) )
  cr:paint()
  cr:set_source( color(args.fg) )

  -- Generate the path
  draw_roundedrect_path(cr, data, width, height, beautiful.menu_corner_radius or radius,padding,args)

  -- Apply
  cr:fill()
  return img
end

local function gen_arrow_x(data,direction)
  local at = data.arrow_type
  local par_center_x = data.parent_geometry and (data.parent_geometry.x + data.parent_geometry.width/2) or -1
  local par_center_y = data.parent_geometry and (data.parent_geometry.y + data.parent_geometry.height/2) or -1
  local menu_beg_x = data.x
  local menu_end_x = data.x + data.width

  if at == base.arrow_type.PRETTY or not at then
    if direction == "left" then
      data._arrow_x = data._internal.w.height -20 - (data.arrow_x_orig or 20)
    elseif direction == "right" then
      --TODO
    elseif direction == "bottom" then
      data._arrow_x = data.width -20 - (data.arrow_x_orig or 20)
      if par_center_x >= menu_beg_x then
        data._arrow_x = data.width - (par_center_x - menu_beg_x) - arrow_height
      end
    elseif direction == "top" then
      --TODO
    end
  elseif at == base.arrow_type.CENTERED then
    if direction == "left" or direction == "right" then
      data._arrow_x = data.height/2 - arrow_height
    else
      data._arrow_x = data.width/2 - arrow_height
    end
  end
end

local function _set_direction(data,direction)
  local height,width = data.height,data.width
  local hash = height*1000+width

  -- Try not to waste time for nothing
  if data._internal._last_direction == direction..(hash) then return end

  -- Avoid recomputing the arrow_x value
  if not data._arrow_x or data._internal.last_size ~= hash then
    gen_arrow_x(data,direction)
    data._internal.last_size = hash
  end

  local border_color = color(beautiful.menu_outline_color or beautiful.menu_border_color or beautiful.fg_normal)
  local geometry = (direction == "left" or direction == "right") and {width = height, height = width} or {height = height, width = width}
  local top_clip_surface        = do_gen_menu_top(data,geometry.width,geometry.height,radius,data.border_width,{bg=border_color or "#0000ff",fg=data.bg or "#00ffff"})
  local top_bounding_surface    = do_gen_menu_top(data,geometry.width,geometry.height,radius,0,{bg="#00000000",fg="#ffffffff"})

  local arr_margin = (data.arrow_type == base.arrow_type.NONE) and 0 or arrow_height
  local angle, swap = angles[direction],swaps[direction]

  --TODO this could be simplified by appling the transform before drawing the bounding mask
  if angle ~= 0 then
    top_bounding_surface = rotate(top_bounding_surface,geometry,angle,swap)
    top_clip_surface     = rotate(top_clip_surface,geometry,angle,swap)
  end

  -- Set the bounding mask
  data.wibox.shape_bounding = top_bounding_surface._native
  data.wibox:set_bg(cairo.Pattern.create_for_surface(top_clip_surface))
  data._internal._need_direction_reload = false
  data._internal._last_direction = direction..(hash)


end

-- Try to avoid useless repaint, this function is heavy
local function set_direction(data,direction)
  data._internal._need_direction = direction
  if not data._internal._need_direction_reload and data._internal._last_direction ~= direction..(data.height*1000+data.width) then
    glib.idle_add(glib.PRIORITY_HIGH_IDLE, function() _set_direction(data,data._internal._need_direction) end)
    data._internal._need_direction_reload = true
  end

  -- Margins need to set manually, a reset will override user changes
  if data.arrow_type ~= base.arrow_type.NONE and (not (data.parent_geometry and data.parent_geometry.is_menu)) and data._internal.former_direction ~= direction then
    if data._internal.former_direction then
      data.margins[data._internal.former_direction] = data.border_width + module.margins[data._internal.former_direction:upper()]
    end
    data.margins[direction] = arrow_height + 2*data.border_width
  end
  data._internal.former_direction = direction
end

local function get_arrow_x(data)
  local height,width = data.height,data.width
  local hash = height*1000+width
  if not data._arrow_x or data._internal.last_size ~= hash then
    gen_arrow_x(data,direction)
--     data._internal.last_size = hash
  end
  return data._arrow_x
end

-- Draw the border on top of items, prevent sharp corners from messing with the border
local function draw_border(self,w, cr, width, height)
  -- Draw the widget content
  self.__draw(self,w, cr, width, height)
  local data = self._data

  -- Create a matrix to rotate the border
  local matrix = cairo.Matrix()
  cairo.Matrix.init_rotate(matrix,angles[data.direction])
  cr:set_matrix(matrix)

  -- Generate the path
  draw_roundedrect_path(cr, data, width, height, beautiful.menu_corner_radius or radius,data.border_width/2)
  cr:set_source(color(beautiful.menu_outline_color or beautiful.menu_border_color or beautiful.fg_normal))
  cr:set_line_width(data.border_width)
  cr:stroke()
end

local function draw(data,args)
  local args = args or {}
  local direction = data.direction or "top"
  if not data.get_arrow_x then
    rawset(data,"arrow_x_orig",data.arrow_x)
    rawset(data,"arrow_x_orig",nil)
    data.get_arrow_x = get_arrow_x
    -- Prevent sharp corners from being over the border
    if data._internal.margin then
      data._internal.margin.__draw = data._internal.margin.draw
      data._internal.margin.draw = draw_border
      if not data._internal.margin._data then
        data._internal.margin._data = data
      end
    end
  end

  set_direction(data,direction)

  --TODO call this less often
  return w,w2
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
