local setmetatable = setmetatable
local beautiful = require( "beautiful"        )
local color     = require( "gears.color"      )
local surface   = require( "gears.surface"    )
local cairo     = require( "lgi"              ).cairo
local base = require( "radical.base" )
local glib = require("lgi").GLib
local shape = require( "gears.shape" )

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
  left   = 3*math.pi/2 , -- 270
  right  = math.pi/2   , -- 90
}

-- If width and height need to be swapped
local swaps = {
  top   =  false,
  bottom=  false,
  right =  true ,
  left  =  true ,
}

-- Generate the arrow position
local function gen_arrow_x(data,direction)
  local at = data.arrow_type
  local par_center_x = data.parent_geometry and (data.parent_geometry.x + data.parent_geometry.width/2) or -1
  local menu_beg_x = data.x

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

-- Generate a rounded cairo path with the arrow
local function draw_roundedrect_path(cr, width, height, radius, data, padding, angle, swap_size)
  local no_arrow      = data.arrow_type == base.arrow_type.NONE
  local padding       = padding or 0
  local arrow_offset  = no_arrow and 0 or padding/2
  local width, height = width - 2*padding - (swap_size and arrow_offset or 0), height - 2*padding - (swap_size and 0 or arrow_offset)

  if swap_size then
    width, height = height - arrow_offset, width
  end

  -- Use rounded rext for sub-menu and
  local s = shape.transform(no_arrow and shape.rounded_rect or shape.infobubble)

  -- Apply transformations
  s = s : rotate_at(width / 2, height / 2, angle)
  if padding > 0 then
    s = s : translate(padding + (swap_size and arrow_offset or 0), padding + (angle == 0 and arrow_offset or 0))
  end

  -- Avoid a race condition
  if (not data._arrow_x) and (not no_arrow) then
    gen_arrow_x(data, data.direction)
  end

  -- the (swap_size and 2 or 1) indicate a bug elsewhere
  s(cr, width, height, radius, arrow_height - arrow_offset, (data._arrow_x or 20) - arrow_offset*(swap_size and 2 or 1))

end

local function _set_direction(data,direction)
  local hash = data.height*1000 + data.width

  -- Try not to waste time for nothing
  if data._internal._last_direction == direction..(hash) then return end

  -- Avoid recomputing the arrow_x value
  if not data._arrow_x or data._internal.last_size ~= hash then
    gen_arrow_x(data,direction)
    data._internal.last_size = hash
  end

  local angle, swap = angles[direction],swaps[direction]

  data._internal._need_direction_reload = false
  data._internal._last_direction = direction..(hash)

  surface.apply_shape_bounding(data.wibox, draw_roundedrect_path, radius, data, 0, angle, swap)
--   surface.apply_shape_clip    (data.wibox, draw_roundedrect_path, radius, data, data.border_width, angle, swap)
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
    data._internal.last_size = hash
  end
  return data._arrow_x
end

-- As the menus have a rounded border, rectangle elements will draw over the
-- corner border. To fix this, this method re-draw the border on top of the
-- content
local function after_draw_children(self, context, cr, width, height)
  local data = self._data

  local dir = data.direction
  local angle, swap = angles[dir], swaps[dir]

  cr:translate(data.border_width/2,data.border_width/2)

  -- Generate the path
  draw_roundedrect_path(cr, width, height, beautiful.menu_corner_radius or radius, data, data.border_width/2, angle, swap)
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

      --TODO eventually restart work on upstreaming this, for now it pull too
      -- much trouble along with it
      data._internal.margin._data = data
      data._internal.margin.after_draw_children = after_draw_children

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
