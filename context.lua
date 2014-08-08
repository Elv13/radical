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
local layout    = require( "radical.layout"   )
local checkbox  = require( "radical.widgets.checkbox" )
local arrow_style = require( "radical.style.arrow" )
local item_mod  = require("radical.item")
local glib = require("lgi").GLib

local capi,module = { mouse = mouse , screen = screen, keygrabber = keygrabber },{}

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

local function set_geometry_real(data)
  local geo = data._internal._next_geometry
  if geo then
    for k,v in pairs(geo) do
      data.wibox[k] = v
    end
  end
  data._internal._next_geometry = nil
  data._internal._need_geometry_reload = nil
end

-- This will update the position before the next loop cycle
-- This avoid tons of round trips with X for dynamic menus
local function change_geometry_idle(data, x, y, w, h)
  data._internal._next_geometry = data._internal._next_geometry or {}
  local geo = data._internal._next_geometry
  geo.x      = x or geo.x
  geo.y      = y or geo.y
  geo.width  = w or geo.width
  geo.height = h or geo.height
  if not data._internal._need_geometry_reload then
    glib.idle_add(glib.PRIORITY_HIGH_IDLE, function() set_geometry_real(data) end)
    data._internal._need_geometry_reload = true
  end
end

local function set_position(self)
  if not self.visible then return end
  local ret,parent = {x=self.x,y=self.y},self.parent_geometry
  local prefx,prefy = self._internal.private_data.x,self._internal.private_data.y
  local src_geo = capi.screen[capi.mouse.screen].geometry
  if parent and parent.is_menu then
    if parent.direction == "right" then
      ret={x=parent.x-self.width,y=parent.y+(self.parent_item.y)}
    else
      ret={x=parent.x+parent.width,y=parent.y+(self.parent_item.y)-self.style.margins.TOP}

      --Handle when the menu doesn't fit in the srceen horizontally
      if ret.x+self.width > src_geo.x + src_geo.width then
        ret.x = parent.x - self.width
      end

      -- Handle when the menu doesn't fit on the screen vertically
      if ret.y+self.height > src_geo.y + src_geo.height then
       ret.y = ret.y - self.height + self.item_height + 2*self.style.margins.TOP
      end
    end
  elseif parent then
    local drawable_geom = parent.drawable.drawable.geometry(parent.drawable.drawable)
    if (self.direction == "left") or (self.direction == "right") then
      ret = {x=drawable_geom.x+((self.direction == "right") and - self.width or drawable_geom.width),y=drawable_geom.y+parent.y+((self.arrow_type ~= base.arrow_type.NONE) and parent.height/2-(self.arrow_x or 20)-6 or 0)}
    else
      ret = {x=drawable_geom.x+parent.x-((self.arrow_type ~= base.arrow_type.NONE) and (self.arrow_x or 20)+11-parent.width/2 or 0),y=(self.direction == "bottom") and drawable_geom.y-self.height or drawable_geom.y+drawable_geom.height}
    end
  elseif prefx ~= 0 or prefy ~= 0 then
    ret = capi.mouse.coords()
    if prefx then
      ret.x = prefx
    end
    if prefy then
      ret.y = prefy
    end
  elseif not parent then --Use mouse position to set position --TODO it is called too often
    ret = capi.mouse.coords()
    local draw = awful.mouse.wibox_under_pointer and awful.mouse.wibox_under_pointer() or awful.mouse.drawin_under_pointer and awful.mouse.drawin_under_pointer()
    if draw then
      local geometry = draw.geometry(draw)
      if self.direction == "top" or self.direction == "bottom" then
        ret.x = ret.x - (self.arrow_x or 20) - 13
        ret.y = geometry.y+geometry.height
        if ret.y+self.height > src_geo.height then
          self.direction = "bottom"
          ret.y = geometry.y-self.height
        end
      end
    end
  end

  --Handle when menu doesn't fit horizontally (if not handled earlier)
  if ret.x+self.width > src_geo.x + src_geo.width then
    ret.x = ret.x - (ret.x+self.width - (src_geo.x + src_geo.width))
  elseif ret.x < 0 then
    ret.x = 0
  end

  change_geometry_idle(self,ret.x,ret.y - 2*(self.wibox.border_width or 0))
end

local function setup_drawable(data)
  local internal = data._internal
  local private_data = internal.private_data

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
  internal.w:set_fg(data.fg)
  internal.w.opacity = data.opacity

  --Getters
  data.get_wibox     = function() return internal.w end
  data.get_x         = function() return data._internal._next_geometry and data._internal._next_geometry.x      or internal.w.x end
  data.get_y         = function() return data._internal._next_geometry and data._internal._next_geometry.y      or internal.w.y end
  data.get_width     = function() return data._internal._next_geometry and data._internal._next_geometry.width  or internal.w.width end
  data.get_height    = function() return data._internal._next_geometry and data._internal._next_geometry.height or internal.w.height end
  data.get_visible   = function() return private_data.visible end
  data.get_direction = function() return private_data.direction end
  data.get_margins   = function()
    local ret = {left=data.border_width,right=data.border_width,top=data.style.margins.TOP,bottom=data.style.margins.BOTTOM}
    if data.arrow_type ~= base.arrow_type.NONE then
      ret[data.direction] = ret[data.direction]+13
    end
    return ret
  end

  --Setters
  data.set_direction = function(_,value)
    if private_data.direction ~= value and (value == "top" or value == "bottom" or value == "left" or value == "right") then
      private_data.direction = value
      local fit_w,fit_h = internal.layout:fit()
      data.height = fit_h
      data.width  = fit_w
    end
  end
  data.set_x      = function(_,value) change_geometry_idle(data,value) end
  data.set_y      = function(_,value) change_geometry_idle(data,nil,value) end
  data.set_width  = function(_,value)
    local need_update = internal.w.width == (value + 2*data.border_width)
    local margins = data.margins
    change_geometry_idle(data,nil,nil,value + data.margins.left + data.margins.right)
    if need_update then
      data.style(data)
    end
  end
  data.set_height = function(_,value)
    local margins = data.margins
    local need_update = (internal.w.height ~= (value + margins.top + margins.bottom))
    local new_height = (value + margins.top + margins.bottom) or 1
    change_geometry_idle(data,nil,nil,nil,new_height > 0 and new_height or 1)
    if need_update then
      data.style(data)
      internal.set_position(data)
    end
  end
  function internal:set_visible(value)
    internal.w.visible = value
    if not value and (not data.parent_geometry or not data.parent_geometry.is_menu) then
      capi.keygrabber.stop()
    end
  end

  if data.visible then
    local fit_w,fit_h = data._internal.layout:fit()
    data.width = fit_w
    data.height = fit_h
  end
end

local function setup_buttons(data,item,args)
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[i] = args["button"..i]
    end
  end

  -- Click to open sub_menu
  if not buttons[1] and data.sub_menu_on == base.event.BUTTON1 then
    buttons[1] = function() item_mod.execute_sub_menu(data,item) end
  end

  --Hide on right click
  if not buttons[3] then
    buttons[3] = function()
      data:hide()
    end
  end

  -- Scroll up
  if not buttons[4] then
    buttons[4] = function()
      data:scroll_up()
    end
  end

  -- Scroll down
  if not buttons[5] then
    buttons[5] = function()
      data:scroll_down()
    end
  end

  item:connect_signal("button::release",function(_m,_i,button_id,mods,geo)
    if #mods == 0 and buttons[button_id] then
      buttons[button_id](_m,_i,mods,geo)
    end
  end)
end

local function setup_item(data,item,args)
  -- Layout
  local f = (data._internal.layout.setup_item) or (layout.vertical.setup_item)
  f(data._internal.layout,data,item,args)

  -- Buttons
  setup_buttons(data,item,args)

  -- Tooltip
  item.widget:set_tooltip(item.tooltip)
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
    ret:connect_signal("_hidden::changed",function(_,item)
      item.widget:emit_signal("widget::updated")
    end)
    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
