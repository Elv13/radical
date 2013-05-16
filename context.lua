local base = require( "radical.base" )
local print = print
local unpack = unpack
local debug = debug
local type = type
local setmetatable = setmetatable
local color     = require( "gears.color"      )
local wibox     = require( "wibox"            )
local beautiful = require( "beautiful"        )
local cairo     = require( "lgi"              ).cairo
local awful     = require( "awful"            )
local util      = require( "awful.util"       )
local button    = require( "awful.button"     )
local layout    = require( "radical.layout"   )
local checkbox  = require( "radical.widgets.checkbox" )
local arrow_style = require( "radical.style.arrow" )

local capi,module = { mouse = mouse , screen = screen , keygrabber = keygrabber },{}

local function get_direction(data)
  local parent_geometry = data.parent_geometry --Local cache to avoid always calling the object hooks
  if not parent_geometry or not parent_geometry.drawable then return "bottom" end
  local drawable_geom = parent_geometry.drawable.drawable.geometry(parent_geometry.drawable.drawable)
  if parent_geometry.y+parent_geometry.height < drawable_geom.height then --Vertical wibox
    if drawable_geom.x > capi.screen[capi.mouse.screen].geometry.width - (drawable_geom.x+drawable_geom.width) then
      return "right"
    else
      return "left"
    end
  else --Horizontal wibox
    if drawable_geom.y > capi.screen[capi.mouse.screen].geometry.height - (drawable_geom.y+drawable_geom.height) then
      return "bottom"
    else
      return "top"
    end
  end
end

local function set_position(self)
  local ret,parent = {x=self.wibox.x,y=self.wibox.y},self.parent_geometry
  if parent and parent.is_menu then
    if parent.direction == "right" then
      ret={x=parent.x-self.width,y=parent.y+(self.parent_item.y)}
    else
      ret={x=parent.x+parent.width,y=parent.y+(self.parent_item.y)}
      if ret.y+self.height > capi.screen[capi.mouse.screen].geometry.height then
        ret.y = ret.y - self.height + self.item_height
      end
    end
  elseif parent then
    local drawable_geom = parent.drawable.drawable.geometry(parent.drawable.drawable)
    if (self.direction == "left") or (self.direction == "right") then
      ret = {x=drawable_geom.x+((self.direction == "right") and - self.wibox.width or drawable_geom.width),y=drawable_geom.y+parent.y+((self.arrow_type ~= base.arrow_type.NONE) and parent.height/2-(self.arrow_x or 20)-6 or 0)}
    else
      ret = {x=drawable_geom.x+parent.x-((self.arrow_type ~= base.arrow_type.NONE) and (self._arrow_x or 20)+11-parent.width/2 or 0),y=(self.direction == "bottom") and drawable_geom.y-self.wibox.height or drawable_geom.y+drawable_geom.height}
    end
  elseif not self.parent_geometry then --Use mouse position to set position --TODO it is called too often
    ret = capi.mouse.coords()
    local draw = awful.mouse.wibox_under_pointer and awful.mouse.wibox_under_pointer() or awful.mouse.drawin_under_pointer and awful.mouse.drawin_under_pointer()
    if draw then
      local geometry = draw.geometry(draw)
      if self.direction == "top" or self.direction == "bottom" then
        ret.x = ret.x - (self.arrow_x or 20) - 13
        ret.y = geometry.y+geometry.height
        if ret.y+self.height > capi.screen[capi.mouse.screen].geometry.height then
          self.direction = "bottom"
          ret.y = geometry.y-self.height
        end
      end
    end
  end
  self.wibox.x = ret.x
  self.wibox.y = ret.y - 2*(self.wibox.border_width or 0)
end

local function setup_drawable(data)
  local internal = data._internal
  local get_map,set_map,private_data = internal.get_map,internal.set_map,internal.private_data

  --Init
  internal.w = wibox({})
  internal.margin = wibox.layout.margin()
  if not data.layout then
    data.layout = layout.vertical
  end
  internal.layout = data.layout(data)
  internal.w.visible = false
  internal.w.ontop = true
  internal.margin:set_widget(internal.layout)
  internal.w:set_widget(internal.margin)

  --Getters
  get_map.wibox     = function() return internal.w end
  get_map.x         = function() return internal.w.x end
  get_map.y         = function() return internal.w.y end
  get_map.width     = function() return internal.w.width end
  get_map.height    = function() return internal.w.height end
  get_map.visible   = function() return internal.w.visible end
  get_map.direction = function() return private_data.direction end
  get_map.margins   = function()
    local ret = {left=data.border_width,right=data.border_width,top=data.style.margins.TOP,bottom=data.style.margins.BOTTOM}
    if data.arrow_type ~= base.arrow_type.NONE then
      ret[data.direction] = ret[data.direction]+13
    end
    return ret
  end

  --Setters
  set_map.direction = function(value)
    if private_data.direction ~= value and (value == "top" or value == "bottom" or value == "left" or value == "right") then
      private_data.direction = value
      local fit_w,fit_h = internal.layout:fit()
      data.height = fit_h
      data.width  = fit_w
    end
  end
  set_map.x      = function(value) internal.w.x      = value end
  set_map.y      = function(value) internal.w.y      = value end
  set_map.width  = function(value)
    local need_update = internal.w.width == (value + 2*data.border_width)
    local margins = data.margins
    internal.w.width  = value + data.margins.left + data.margins.right
    if need_update then
      data.style(data)
    end
  end
  set_map.height = function(value)
    local margins = data.margins
    local need_update = (internal.w.height ~= (value + margins.top + margins.bottom))
    internal.w.height = value + margins.top + margins.bottom
    if need_update then
      data.style(data)
      internal.set_position(data)
    end
  end
  function internal:set_visible(value)
    internal.w.visible = value
  end
  local fit_w,fit_h = data._internal.layout:fit()
  data.width = fit_w
end

local function setup_item(data,item,args)
  --Create the background
  item.widget = wibox.widget.background()
  data.item_style(data,item,false,false)
  item.widget:set_fg(item._private_data.fg)

  --Event handling
  item.widget:connect_signal("mouse::enter", function() item.selected = true end)
  item.widget:connect_signal("mouse::leave", function() item.selected = false end)
  data._internal.layout:add(item)
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[#buttons+1] = button({},i,args["button"..i])
    end
  end
  if not buttons[3] then --Hide on right click
    buttons[#buttons+1] = button({},3,function()
      data.visible = false
      if data.parent_geometry and data.parent_geometry.is_menu then
        data.parent_geometry.visible = false
      end
    end)
  end

  --Be sure to always hide sub menus, even when data.visible is set manually
  data:connect_signal("visible::changed",function(_,vis)
    if data._tmp_menu and data.visible == false then
      data._tmp_menu.visible = false
    end
  end)
  data:connect_signal("parent_geometry::changed",function(_,vis)
    local fit_w,fit_h = data._internal.layout:fit()
    data.height = fit_h
    data.style(data)
  end)
  item.widget:buttons( util.table.join(unpack(buttons)))

  --Create the main item layout
  local l,la,lr = wibox.layout.fixed.horizontal(),wibox.layout.align.horizontal(),wibox.layout.fixed.horizontal()
  local m = wibox.layout.margin(la)
  m:set_margins (0)
  m:set_left  ( data.item_style.margins.LEFT   )
  m:set_right ( data.item_style.margins.RIGHT  )
  m:set_top   ( data.item_style.margins.TOP    )
  m:set_bottom( data.item_style.margins.BOTTOM )
  local text_w = wibox.widget.textbox()
  item._private_data._fit = wibox.widget.background.fit
  m.fit = function(...)
      if item.visible == false or item._filter_out == true then
        return 0,0
      end
      return data._internal.layout.item_fit(data,item,...)
  end
  
  if data.fkeys_prefix == true then
    local pref = wibox.widget.textbox()
    pref.draw = function(self,w, cr, width, height)
      cr:set_source(color(beautiful.fg_normal))
      cr:paint()
      wibox.widget.textbox.draw(self,w, cr, width, height)
    end
    pref:set_markup("<span fgcolor='".. beautiful.bg_normal .."'><tt><b>F11</b></tt></span>")
    l:add(pref)
    m:set_left  ( 0 )
  end

  if args.prefix_widget then
    l:add(args.prefix_widget)
  end

  if args.icon then
    local icon = wibox.widget.imagebox()
    icon:set_image(args.icon)
    l:add(icon)
  end
  text_w:set_markup(item._private_data.text)
  l:add(text_w)
  if item._private_data.sub_menu_f or item._private_data.sub_menu_m then
    local subArrow  = wibox.widget.imagebox() --TODO, make global
    subArrow.fit = function(box, w, h) return subArrow._image:get_width(),item.height end
    subArrow:set_image( beautiful.menu_submenu_icon   )
    lr:add(subArrow)
    item.widget.fit = function(box,w,h,...)
      args.y = data.height-h-data.margins.top
      return wibox.widget.background.fit(box,w,h,...)
    end
  end
  if item.checkable then
    item._internal.get_map.checked = function()
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked()
      else
        return item._private_data.checked
      end
    end
    local ck = wibox.widget.imagebox()
    ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    lr:add(ck)
    item._internal.set_map.checked = function (value)
      item._private_data.checked = value
      ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    end
  end
  if args.suffix_widget then
    lr:add(args.suffix_widget)
  end
  la:set_left(l)
  la:set_right(lr)
  item.widget:set_widget(m)
  local fit_w,fit_h = data._internal.layout:fit()
  data.height = fit_h
  data.style(data)
end


local function new(args)
    local args = args or {}
    args.internal = args.internal or {}
    args.internal.get_direction  = args.internal.get_direction or get_direction
    args.internal.set_position   = args.internal.set_position or set_position
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item or setup_item
    args.style = args.style or arrow_style
    local ret = base(args)
    ret:connect_signal("clear::menu",function(_,vis)
      ret._internal.layout:reset()
    end)
    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;