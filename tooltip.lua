local setmetatable,math = setmetatable,math
local beautiful = require( "beautiful"      )
local surface   = require( "gears.surface"  )
local wibox     = require( "wibox"          )
local object    = require( "radical.object" )
local shape     = require( "gears.shape"    )
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

local function init(data,widget,args)
  if widget and not data.init then
    data.init = true

    -- Setup the wibox
    local vertical = (args.direction == "left") or (args.direction == "right")
    local w,extents = data.wibox or wibox{},widget._private.layout:get_pixel_extents()
    extents.width = extents.width + 60
    w.visible = false
    w.width   = extents.width
    w.height  = vertical and 20 or 25
    w.ontop   = true
    w:set_bg(beautiful.tooltip_bg or beautiful.bg_normal or "")

    -- Pick the right shape
    local s = nil
    if args.direction == "bottom" then
      s = shape.infobubble
    elseif args.direction == "top" then
      s = shape.transform(shape.infobubble) : rotate_at(w.width/2, w.height/2, math.pi)
    elseif args.direction == "left" then
      s = shape.transform(shape.rectangular_tag) : rotate_at(w.width/2, w.height/2, math.pi)
    else
      s = shape.rectangular_tag
    end

    surface.apply_shape_bounding(w, s, w.height/2 - 2.5, 5)

    data.wibox = w
  end
end

local function set_text(self,text)
  self.init = nil
  self._text = text
  if self._w then
    self._w:set_markup("<b>".. self._text .."</b>")
  end
  init(self,self._w,self._args)
end

local function set_markup(self,text)
  self.init = nil
  self._text = text
  if self._w then
    self._w:set_markup(self._text)
  end
  init(self,self._w,self._args)
end


local function new(widget,text, args)
  args = args or {}

  local data = object({
    private_data  = {
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })

  data._text = text

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
    args2 = args2 or args or {}
    args.direction = args.direction or get_direction(args2)

    local vertical,textw = (args.direction == "left") or (args.direction == "right"),wibox.widget.textbox()
    textw.align = "center"

    if not args.is_markup then
      textw:set_markup("<b>".. data._text .."</b>")
    else
      textw:set_markup(data._text)
    end

    data._w = textw
    init(data,textw,args)

    if data.wibox then

      local l,m = wibox.layout.fixed.horizontal(),wibox.container.margin(textw)
      m:set_left    ( 30 )
      m:set_right   ( 10 )
      m:set_bottom  ( not vertical and ((args.direction == "top") and 4 or -4) or 0 )
      l:add(m)

      l:fill_space(true)
      data.wibox:set_widget(l)

      data.wibox:connect_signal("mouse::leave",hide_tooltip)
      local relative_to_parent = rel_parent(data.wibox,args2,args)
      data.wibox.x = math.floor(args2.x or args.x or relative_to_parent.x or capi.mouse.coords().x - data.wibox.width/2 -5)
      data.wibox.y = math.floor(args2.y or args.y or relative_to_parent.y or ((not vertical) and capi.screen[capi.mouse.screen].geometry.height - 16 - 25 or 16))
      data.wibox.visible = true
      if args2.parent and args2.parent.drawable and data.drawable ~= args2.parent.drawable then
        data.drawable = args2.parent.drawable
        data.drawable:connect_signal("mouse::leave",hide_tooltip)
      end
    end
  end
  widget:connect_signal("mouse::enter"  , function(_,geometry) data:showToolTip( true  , {parent=geometry}) end)
  widget:connect_signal("mouse::leave"  , hide_tooltip)
  widget:connect_signal("button::press" , hide_tooltip)
  data.set_text   = set_text
  data.set_markup = set_markup
  data._args = args
  return data
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
