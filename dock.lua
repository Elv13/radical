local setmetatable,unpack,table = setmetatable,unpack,table
local math = math
local base       = require( "radical.base"                 )
local color      = require( "gears.color"                  )
local wibox      = require( "wibox"                        )
local beautiful  = require( "beautiful"                    )
local cairo      = require( "lgi"                          ).cairo
local awful      = require( "awful"                        )
local util       = require( "awful.util"                   )
local fkey       = require( "radical.widgets.fkey"         )
local button     = require( "awful.button"                 )
local checkbox   = require( "radical.widgets.checkbox"     )
local vertical   = require( "radical.layout.vertical"      )
local horizontal = require( "radical.layout.horizontal"    )
local item_layout= require( "radical.item.layout.icon"     )
local item_style = require( "radical.item.style.rounded"   )
local glib       = require( "lgi"                          ).GLib
local margins2   = require("radical.margins"               )

local capi,module = { mouse = mouse , screen = screen, keygrabber = keygrabber },{}
local max_size = {height={},width={}}

local default_radius = 10

local dir_to_deg = {left=0,bottom=math.pi/2,right=math.pi,top=3*(math.pi/2)}

local function get_direction(data)
  local dir = data._internal.position or "left"
  return dir,dir_to_deg[dir]--"left" -- Nothing to do
end

--No, screen 1 is not always at x=0, yet
local function get_first_screen()
  for i=1,capi.screen.count() do
    if capi.screen[i].geometry.x == 0 then
      return i
    end
  end
end




------------------------------------
--     Drawing related code       --
------------------------------------

local function rotate2(img, geometry, angle,swap_size)
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

-- Draw the round corners
local function mask(rotate,width,height,radius,offset,anti,bg,fg)
  local invert = (rotate ~= 0) and (rotate ~= math.pi)
  local width,height = invert and height or width,invert and width or height
  local img = cairo.ImageSurface.create(cairo.Format.ARGB32, width, height)
  local cr = cairo.Context(img)
  cr:set_operator(cairo.Operator.SOURCE)
  cr:set_antialias(anti)
  cr:rectangle(0, 0, width, height)
  cr:set_source(bg)
  cr:fill()
  cr:set_source(fg)
  cr:arc(width-radius-1-offset,radius+offset*2,radius,0,2*math.pi)
  cr:arc(width-radius-1-offset,height-radius-2*offset,radius,0,2*math.pi)
  cr:rectangle(0, offset, width-radius-1, height-2*offset)
  cr:rectangle(width-radius-1-offset, radius+2*offset, radius, height-2*radius-2*offset)
  cr:fill()
  return rotate~=0 and rotate2(img,{width=width,height=height},rotate,true) or img
end

-- Do not draw over the boder, ever
local function dock_draw(self, w, cr, width, height)

  -- Generate the border surface
  if not self.mask or self.mask_hash ~= width*1000+height then
    local dir,rotation = get_direction(self.data)
    self.mask = mask(rotation,w.width,w.height,(beautiful.dock_corner_radius or default_radius) - 2,1,0,color(self.data.border_color or seld.data.fg),color("#FF000000"))
    self.mask_hash = width*1000+height
  end
  cr:save()

  --Draw the border
  self.__draw(self, w, cr, width, height)
  cr:set_source_surface(self.mask)
  cr:paint()
  cr:restore()
end


--Make sure the wibox is at the center of the screen
local function align_wibox(w,direction,screen)
  local axis = (direction == "left" or direction == "right") and "height" or "width"
  local offset = axis == "height" and "y" or "x"
  local src_geom = capi.screen[screen].geometry
  local scr_size = src_geom[offset] + (src_geom[axis] - w[axis]) /2

  w[offset] = scr_size
  if direction == "left" then
    w.x = src_geom.x
  elseif direction == "right" then
    w.x = src_geom.x + src_geom.width - w.width
  elseif direction == "bottom" then
    w.y = src_geom.y+src_geom.height-w.height
  else
    w.y = src_geom.y
  end
end




-----------------------------------------
--    Size and position related code   --
-----------------------------------------

-- Change the position, TODO
local function set_position(self,value)
  self._internal.position = value
end

local function get_position(self,value)
  return self._internal.position
end

-- Compute the optimal maxmimum size
local function get_max_size(data,screen)
  local dir = get_direction(data)
  local w_or_h = ((dir == "left" or dir == "right") and "height" or "width")
  local x_or_y = w_or_h == "height" and "y" or "x"
  local res = max_size[w_or_h][screen]
  if not res then
    local full,wa = capi.screen[screen].geometry[w_or_h],capi.screen[screen].workarea
    local top,bottom = wa[x_or_y],full-(wa.y+wa[w_or_h])
    local biggest = top > bottom and top or bottom
    --res = full - biggest*2 - 52 -- 26px margins
    res = wa[w_or_h] - 52 -- 26px margins
    max_size[w_or_h][screen] = res
  end
  return res
end

-- local function get_size(data,screen)
--   local max = get_max_size(data,screen)
--   if data._internal.orientation == "vertical" and h > max then
--     
--   elseif data._internal.orientation == "horizontal" and w > max then
--     
--   end
--   return w,h,max
-- end

-- The dock always have to be shorter than the screen
local function adapt_size(data,w,h,screen)
  local max = get_max_size(data,screen)

  -- Get the current size, then compare and ajust
  local fit_w,fit_h = data._internal.layout:fit(20,9999,true)
  
  -- Get the number of items minus the number of widgets
  -- This can be used to approximate the number of pixel to remove
  local visible_item = data.visible_row_count - #data._internal.widgets + 1

  if data._internal.orientation == "vertical" and h > max then
    local wdg_height = data.widget_fit_height_sum
    --TODO this assume the widget size wont change
--     data.item_height = math.ceil((data.item_height*max)/h) --OLD
    data.item_height = math.ceil((max-wdg_height)/visible_item)
    w = data.item_height
    h = max
    data.item_width  = w
    data.menu_width  = w
    w = w + data.margins.left+data.margins.right
    data.default_width = w
    data._internal.private_data.width = w
  elseif data._internal.orientation == "horizontal" and w > max then
    --TODO merge this with above
    local wdg_width = data.widget_fit_width_sum
    data.item_width = math.ceil((data.item_height*max)/w)
    data._internal.private_data = data.item_width
    w = max
    h = data.item_width
    data.item_height  = h
    data.menu_height  = h
    h = h + data.margins.bottom+data.margins.top
--     data.default_width = h
  end
  if data.icon_size and data.icon_size > w then
    data.icon_size = w
  end
  data._internal._geom_vals = nil
  return w,h
end

-- Create the auto hiding wibox
local function get_wibox(data, screen)
  if data._internal.w then return data._internal.w end
  data:emit_signal("dock::request")

  local dir,rotation = get_direction(data)
  local geo_src = data._internal._geom_vals or data

  -- Need to be created befoce calling align_wibox
  local m = wibox.layout.margin()
  m:set_widget(data._internal.layout)
  m:set_margins(0)
  data._internal.mrgns.widget = m

  -- Make sure the down will fit on the screen
  geo_src.width,geo_src.height = adapt_size(data,geo_src.width,geo_src.height,screen)

  local w = wibox{ screen = screen, width = geo_src.width, height = geo_src.height,ontop=true}
  align_wibox(w,dir,screen)

  w:set_widget(m)
  data._internal.w = w

  -- Create the rounded corner mask
  w:set_bg(cairo.Pattern.create_for_surface(mask(rotation,w.width,w.height,(beautiful.dock_corner_radius or default_radius)-2,1,0,color(beautiful.fg_normal),color(beautiful.bg_dock or beautiful.bg_normal))))
  w.shape_bounding  = mask(rotation,w.width,w.height,beautiful.dock_corner_radius or default_radius,0,1,color("#00000000"),color("#FFFFFFFF"))._native
  local function prop_change()
    w:set_bg(cairo.Pattern.create_for_surface(mask(rotation,w.width,w.height,(beautiful.dock_corner_radius or default_radius) -2,1,0,color(beautiful.fg_normal),color(beautiful.bg_dock or beautiful.bg_normal))))
    w.shape_bounding  = mask(rotation,w.width,w.height,beautiful.dock_corner_radius or default_radius,0,1,color("#00000000"),color("#FFFFFFFF"))._native
  end
  w:connect_signal("property::height",prop_change)
  w:connect_signal("property::width" ,prop_change)

  -- Hide the dock when the mouse leave
  w:connect_signal("mouse::leave",function()
    if not (data._tmp_menu and data._tmp_menu.visible) then
      data.visible = false
    end
  end)
  data:emit_signal("visible::changed",true)

  -- Bring back the placeholder when hiding
  data:connect_signal("visible::changed",function(data,val)
    if not val then
      data._internal.placeholder.visible = true
    end
  end)

  return w
end

-- Create the "hidden" wibox that display the first one on command
local function create_placeholder(data)
  local screen,dir = data.screen or get_first_screen() or 1,get_direction(data)
  local h_or_w = (dir == "left" or dir == "right") and "width" or "height"
  local hw_invert = h_or_w == "height" and "width" or "height"
  local placeholder = wibox{ screen = screen, [h_or_w] = 1,[hw_invert] = 1,bg="#00000000", ontop = true,visible=true }

  placeholder:geometry({ [h_or_w] = 1, [hw_invert] = capi.screen[screen].geometry.height -100, x = dir == "right" and capi.screen[screen].geometry.width -1 or 0, y = capi.screen[screen].geometry.y + 50})


  -- Raise of create the main dock wibox
  placeholder:connect_signal("mouse::enter", function()
    get_wibox(data,screen).visible = true
    placeholder.visible = false
  end)

  -- Move the placeholder when the wibox is resized
  data:connect_signal(((dir == "left" or dir == "right") and "height" or "width").."::changed",function()
--     placeholder[hw_invert] = data[hw_invert]
    align_wibox(placeholder,dir,screen)
  end)
  data._internal.placeholder = placeholder

  -- Adapt the size when new items are added
  data:connect_signal("layout_size",function(_,w,h)
    if not data._internal._has_changed then
      glib.idle_add(glib.PRIORITY_DEFAULT_IDLE, function()
        if not data._internal._geom_vals then return end
        local w,h,internal = data._internal._geom_vals.width,data._internal._geom_vals.height,data._internal

        if h == 0 then
          h = 1
        end
        if w == 0 then
          w = 1
        end

        -- Resize the placeholder
        internal.placeholder[hw_invert] = (hw_invert == "height") and h or w
        align_wibox(internal.placeholder,dir,screen)

        -- Resize the dock wibox
        if internal.w then
          w,h=adapt_size(data,w,h,screen) --TODO place holder need to do
          internal.w.height = h
          internal.w.width  = w
          align_wibox(internal.w,dir,screen)
        end

        data._internal._has_changed = false
      end)
    end
    data._internal._geom_vals = {height=h,width=w}
    data._internal._has_changed = true
  end)

end

local function setup_drawable(data)
  local internal = data._internal
  local private_data = internal.private_data

  -- Create the layout
  internal.layout        = data.layout(data)
  internal.layout.__draw = internal.layout.draw
  internal.layout.draw   = dock_draw
  internal.layout.data   = data

  -- Getters
  data.get_x         = function() return 0                                              end
  data.get_y         = function() return 0                                              end
  data.get_width     = function()
    return internal.w and internal.w.width or data._internal.layout:fit(9999,9999,true)
  end
  data.get_height    = function()
    if internal.orientation == "horizontal" then
      return beautiful.default_height
    else
       local w,h = internal.layout.fit(internal.layout,9999,9999)
       return h
    end
  end
  data.get_visible   = function() return true                                           end
  data.get_direction = get_direction

  local mrgns = margins2(nil,{})
  data._internal.mrgns = mrgns
  data.get_margins = function()
    return data._internal.mrgns or {}
  end

  function data:set_visible(value)
    if internal.w then
      internal.w.visible = value or false
    end
  end

  -- This widget do not use wibox, so setup correct widget interface
  data.fit  = internal.layout
  data.draw = internal.layout
end

local function setup_item(data,item,args)
  -- Add widgets
  local f = (data._internal.layout.setup_item) or (layout.vertical.setup_item)
  f(data._internal.layout,data,item,args)

  -- Buttons
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[i] = args["button"..i]
    end
  end

  item:connect_signal("button::release",function(_m,_i,button_id,mods,geo)
    if #mods == 0 and buttons[button_id] then
      buttons[button_id](_m,_i,mods,geo)
    end
  end)

  -- Tooltip
  item.widget:set_tooltip(item.tooltip)
end

local function new(args)
  local args = args or {}
  local orientation = (not args.position or args.position == "left" or args.position == "right") and "vertical" or "horizontal"
  local length_inv  = orientation == "vertical" and "width" or "height"

  -- The the Radical arguments
  args.internal = args.internal or {}
  args.internal.orientation = orientation
  args.internal.get_direction  = args.internal.get_direction  or get_direction
  args.internal.set_position   = args.internal.set_position   or set_position
  args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
  args.internal.setup_item     = args.internal.setup_item     or setup_item
  args.item_style              = args.item_style              or item_style
  args.bg                   = color("#00000000") --Use the dock bg instead
  args.item_height          = 40
  args.item_width           = 40
  args.sub_menu_on          = args.sub_menu_on or base.event.BUTTON1
  args.internal             = args.internal or {}
  args.internal.layout_func = orientation == "vertical" and vertical or horizontal
  args.layout               = args.layout or args.internal.layout_func
  args.item_style           = args.item_style or item.style
  args.item_layout          = args.item_layout or item_layout
  args[length_inv]          = args[length_inv] or 40

  -- Create the dock
  local ret = base(args)
  ret.set_position = set_position
  ret.get_position = get_position
  ret.position = args.position or "left"
  ret.screen = args.screen

  -- Add a 1px placeholder to trigger it
  create_placeholder(ret)

  return ret
end


return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
