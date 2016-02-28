local setmetatable = setmetatable
local beautiful    = require( "beautiful"                  )
local color        = require( "gears.color"                )
local cairo        = require( "lgi"                        ).cairo
local wibox        = require( "wibox"                      )
local checkbox     = require( "radical.widgets.checkbox"   )
local fkey         = require( "radical.widgets.fkey"       )
local infoshapes   = require( "radical.widgets.infoshapes" )
local theme        = require( "radical.theme"              )
local util         = require( "awful.util"                 )
local margins2     = require( "radical.margins"            )
local shape        = require( "gears.shape"                )
local surface      = require( "gears.surface"              )

local module = {}

-- Add [F1], [F2] ... to items
function module:setup_fkey(item,data)
  item.set_f_key = function(_,value)
    item._internal.has_changed = true
    item._internal.f_key = value
    data:remove_key_hook("F"..value)
    data:add_key_hook({}, "F"..value      , "press", function()
      item.button1(data,menu)
      data.visible = false
    end)
  end
  item.get_f_key = function() return item._internal.f_key end
end

function module.after_draw_children(self, context, cr, width, height)
    --TODO get rid of this, use the stack container
    if self._item.overlay_draw then
        self._item.overlay_draw(context,self._item,cr,width,height)
    end
end

-- Apply icon transformation
function module.set_icon(self,image)
  if self._data.icon_transformation then
    self._item._original_icon = image
    image = self._data.icon_transformation(image,self._data,self._item)
  end
  wibox.widget.imagebox.set_image(self,image)
end

-- Setup the item icon
function module:setup_icon(item,data)
  local icon = wibox.widget.imagebox()
  icon._data = data
  icon._item = item
  icon.set_image = module.set_icon
  if item.icon then
    icon:set_image(item.icon)
  end

  item.set_icon = function (_,value)
    icon:set_image(value)
  end
  return icon
end

-- Show the checkbox
function module:setup_checked(item,data)
  if item.checkable then
    item.get_checked = function()
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked(data,item)
      else
        return item._private_data.checked
      end
    end
    local ck = wibox.widget.imagebox()
    ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    item.set_checked = function (_,value)
      item._private_data.checked = value
      ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
      item._internal.has_changed = true
    end
    return ck
  end
end

-- Setup hover
function module:setup_hover(item,data)
  item.set_hover = function(_,value)
    local item_style = item.item_style or data.item_style
    item.state[-1] = value and true or nil
    item_style(item,{})
  end
end

-- Create sub_menu arrows
local sub_arrow = nil
function module:setup_sub_menu_arrow(item,data)
  if (item._private_data.sub_menu_f or item._private_data.sub_menu_m) and not data.disable_submenu_icon then
    if not sub_arrow then
      sub_arrow = wibox.widget.imagebox() --TODO, make global
      sub_arrow.fit = function(box, context,w, h) return (sub_arrow._image and sub_arrow._image:get_width() or 0),item.height end

      if beautiful.menu_submenu_icon then
        sub_arrow:set_image( beautiful.menu_submenu_icon   )
      else
        local h = data.item_height
        sub_arrow:set_image(surface.load_from_shape(7, h,
          shape.transform(shape.isosceles_triangle) : rotate_at(3.5,h/2,math.pi/2),
          beautiful.menu_fg_normal or beautiful.menu_fg or beautiful.fg_normal
        ))
      end
    end
    return sub_arrow
  end
end

-- Proxy all events to the parent
function module.setup_event(data,item,widget)
  local widget = widget or item.widget

  -- Setup data signals
  widget:connect_signal("button::press",function(_,__,___,id,mod,geo)
    local mods_invert = {}
    for k,v in ipairs(mod) do
      mods_invert[v] = i
    end

    item.state[4] =  true
    data:emit_signal("button::press",item,id,mods_invert,geo)
    item:emit_signal("button::press",data,id,mods_invert,geo)
  end)
  widget:connect_signal("button::release",function(wdg,__,___,id,mod,geo)
    local mods_invert = {}
    for k,v in ipairs(mod) do
      mods_invert[v] = i
    end
    item.state[4] =  nil
    data:emit_signal("button::release",item,id,mods_invert,geo)
    item:emit_signal("button::release",data,id,mods_invert,geo)
  end)
  widget:connect_signal("mouse::enter",function(b,mod,geo)
    data:emit_signal("mouse::enter",item,mod,geo)
    item:emit_signal("mouse::enter",data,mod,geo)
  end)
  widget:connect_signal("mouse::leave",function(b,mod,geo)
    data:emit_signal("mouse::leave",item,mod,geo)
    item:emit_signal("mouse::leave",data,mod,geo)
  end)

  -- Always tracking mouse::move is expensive, only do it when necessary
--   local function conn(b,t)
--     item:emit_signal("mouse::move",item)
--   end
--   item:connect_signal("connection",function(_,name,count)
--     if name == "mouse::move" then
--       widget:connect_signal("mouse::move",conn)
--     end
--   end)
--   item:connect_signal("disconnection",function(_,name,count)
--     if count == 0 then
--       widget:connect_signal("mouse::move",conn)
--     end
--   end)
end

-- Create the actual widget
local function create_item(item,data,args)

  -- F keys
  module:setup_fkey(item,data)

  -- Icon
  local icon = module:setup_icon(item,data)
  icon.fit = function(...)
    local w,h = wibox.widget.imagebox.fit(...)
    return w+3,h
  end

  if data.icon_per_state == true then
    item:connect_signal("state::changed",function(i,d,st)
      if item._original_icon and data.icon_transformation then
        wibox.widget.imagebox.set_image(icon,data.icon_transformation(item._original_icon,data,item))
      end
    end)
  end

  -- Text
  local tb = wibox.widget.textbox()

  tb:set_text(item.text)
  item.set_text = function (_,value)
    if data.disable_markup then
      tb:set_text(value)
    else
      tb:set_markup(value)
    end
    item._private_data.text = value
  end

  -- Hover
  module:setup_hover(item,data)

  -- Overlay
  item.set_overlay = function(_,value)
    item._private_data.overlay = value
    item.widget:emit_signal("widget::updated")
  end

    -- Define the item layout
    item.widget = wibox.widget.base.make_widget_declarative {
        -- Widgets
        {

            -- Widget
            {
                -- This is where the content is placed

                -- Widgets
                {
                    -- The prefixes

                    -- Widget
                    data.fkeys_prefix and fkey(data,item) or nil,
                    icon                                        ,
                    args.prefix_widget                          ,

                    -- Attributes
                    layout = wibox.layout.fixed.horizontal
                },
                {
                    -- Underlay and overlay
                    tb,

                    -- Attributes
                    widget     = infoshapes,
                    spacing    = 10,
                    infoshapes = item.infoshapes,
                    id         = "infoshapes",
                },
                {
                    -- Suffixes

                    -- Widget
                    module:setup_checked(item,data)       ,
                    module:setup_sub_menu_arrow(item,data),
                    args.suffix_widget                    ,

                    -- Attributes
                    layout = wibox.layout.fixed.horizontal
                },

                -- Attributes
                _item  = item                         ,
                _data  = data                         ,
                id     = "main_align"                 ,
                layout = wibox.layout.align.horizontal,
            },

            -- Attributes
            id     = "main_margin"      ,
            layout = wibox.layout.margin,
        },

        -- Attributes
        fg      = item._private_data.fg  ,
        tooltip = item.tooltip           ,
        _item   = item                   ,
        _data   = data                   ,
        widget  = wibox.widget.background,
    }

    -- Make some widgets easier to access
    item._internal.margin_w = item.widget:get_children_by_id("main_margin")[1]
    item._internal.align    = item.widget:get_children_by_id("main_align" )[1]

    -- Override some methods
    item._internal.text_w            = tb
    item._internal.icon_w            = icon

    -- Export the margin
    local mrgns = margins2(
        item._internal.margin_w,
        util.table.join(
            (item.item_style or data.item_style).margins,data.default_item_margins
        )
    )

    function item:get_margins()
        return mrgns
    end

    -- Draw
    local item_style = item.style or data.item_style
    item_style(item,{})

    -- Setup events
    module.setup_event(data,item)

    return item.widget
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
