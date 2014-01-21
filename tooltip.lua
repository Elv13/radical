local setmetatable,math = setmetatable,math
local beautiful = require( "beautiful"    )
local wibox     = require( "wibox"        )
local cairo     = require( "lgi"          ).cairo
local capi = { screen = screen ,
               mouse  = mouse  }
local module={}

local function get_direction(args)
  if not args.parent or not args.parent.drawable then return "bottom" end
  local drawable_geom = args.parent.drawable.drawable.geometry(args.parent.drawable.drawable)
  if args.parent.y+args.parent.height < drawable_geom.height then --Vertical wibox
    if drawable_geom.x > capi.screen[capi.mouse.screen].geometry.width - (drawable_geom.x+drawable_geom.width) then
      return "left"
    else
      return "right"
    end
  else --Horizontal wibox
    if drawable_geom.y > capi.screen[capi.mouse.screen].geometry.height - (drawable_geom.y+drawable_geom.height) then
      return "top"
    else
      return "bottom"
    end
  end
end

local function rel_parent(w,args2,args)
  if args2 and args2.parent then
    local drawable_geom = args2.parent.drawable.drawable.geometry(args2.parent.drawable.drawable)
    if (args.direction == "left") or (args.direction == "right") then
      return {x=drawable_geom.x+((args.direction == "left") and - w.width or drawable_geom.width),y=drawable_geom.y+args2.parent.y+args2.parent.height/2-w.height/2}
    else
      return {x=drawable_geom.x+args2.parent.x-w.width/2 + args2.parent.width/2,y=(args.direction == "top") and drawable_geom.y-w.height or drawable_geom.y+drawable_geom.height}
    end
  end
  return {}
end

local function new(widget,text, args)
  local args,data = args or  {},{}

  data.text = text

  local function hide_tooltip()
    if data.wibox then
      data.wibox.visible = false
      if data.drawable then
        data.drawable:disconnect_signal("mouse::leave",hide_tooltip)
        data.drawable = nil
      end
    end
  end

  function data:hide() hide_tooltip() end

  function data:showToolTip(show,args2)
    local args2 = args2 or args or {}
    args.direction = args.direction or get_direction(args2)
    if not data.wibox then
      local vertical,textw = (args.direction == "left") or (args.direction == "right"),wibox.widget.textbox()
      textw.align = "center"
      textw:set_markup("<b>".. data.text .."</b>")
      local w,extents = wibox({position="free"}),textw._layout:get_pixel_extents()
      extents.width = extents.width + 60
      w.visible = false
      w.width   = extents.width
      w.height  = vertical and 20 or 25
      w.ontop   = true
      w:set_bg(beautiful.tooltip_bg or beautiful.bg_normal or "")

      local img = cairo.ImageSurface(cairo.Format.A1, extents.width, vertical and 20 or 25)
      local cr = cairo.Context(img)
      --Clear the surface
      cr:set_source_rgba( 0, 0, 0, 0 )
      cr:paint()

      --Draw the corner
      cr:set_source_rgba( 1, 1, 1, 1 )
      if not (vertical) then
          cr:arc(20-(vertical and 5 or 0), 20/2 + (5), 20/2 - 1,0,2*math.pi)
      end
      cr:arc(extents.width-20+(2*(vertical and 5 or 0)), 20/2 + (vertical and 0 or 5), 20/2 - 1,0,2*math.pi)

      --Draw arrow
      if not (vertical) then
          for i=0,(5) do
              cr:rectangle(extents.width/2 - 5 + i ,5-i, 1, i)
              cr:rectangle(extents.width/2 + 5 - i ,5-i, 1, i)
          end
      else
          for i=0,(12) do
              cr:rectangle(i, (20/2) - i, i, i*2)
          end
      end
      cr:rectangle(20-((vertical) and 5 or 0),vertical and 0 or 5, extents.width-40+((vertical) and 14 or 0 ), 20)
      cr:fill()
      local l,m = wibox.layout.fixed.horizontal(),wibox.layout.margin(textw)
      m:set_left    ( 30 )
      m:set_right   ( 10 )
      m:set_bottom  ( not vertical and ((args.direction == "top") and 4 or -4) or 0 )
      l:add(m)
      l:fill_space(true)
      w:set_widget(l)
      w:set_fg(beautiful.fg_normal)

      if args.direction == "left" or args.direction == "top" then --Mirror
        local matrix,pattern = cairo.Matrix(),cairo.Pattern.create_for_surface(img)
        cairo.Matrix.init_rotate(matrix,math.pi)
        matrix:translate(-extents.width,-((vertical) and 20 or 25))
        pattern:set_matrix(matrix)
        local img2 = cairo.ImageSurface(cairo.Format.A1, extents.width, vertical and 20 or 25)
        local cr2 = cairo.Context(img2)
        cr2:set_source(pattern)
        cr2:paint()
        img = img2
      end
      w.shape_bounding  = img._native

      w:connect_signal("mouse::leave",hide_tooltip)
      data.wibox = w
    end
    if data.wibox then
      local relative_to_parent = rel_parent(data.wibox,args2,args)
      data.wibox.x = args2.x or args.x or relative_to_parent.x or capi.mouse.coords().x - data.wibox.width/2 -5
      data.wibox.y = args2.y or args.y or relative_to_parent.y or ((not vertical) and capi.screen[capi.mouse.screen].geometry.height - 16 - 25 or 16)
      data.wibox.visible = true
      if args2.parent and args2.parent.drawable and data.drawable ~= args2.parent.drawable then
        data.drawable = args2.parent.drawable
        data.drawable:connect_signal("mouse::leave",hide_tooltip)
      end
    end
  end
  widget:connect_signal("mouse::enter"  , function(widget,geometry) data:showToolTip( true  , {parent=geometry}) end)
  widget:connect_signal("mouse::leave"  , hide_tooltip)
  widget:connect_signal("button::press" , hide_tooltip)
  return data
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
