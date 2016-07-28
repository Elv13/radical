local wibox     = require( "wibox"     )
local beautiful = require( "beautiful" )

local module = {}

-- Apply icon transformation
local function set_icon(self,image)
    if self._data.icon_transformation then
        self._item._original_icon = image
        image = self._data.icon_transformation(image,self._data,self._item)
    end
    wibox.widget.imagebox.set_image(self,image)
end

-- Setup the item icon
function module.setup_icon(item,data) --TODO maybe create a proper widget
    local icon = wibox.widget.imagebox()

    rawset(icon, "_data"    , data    )
    rawset(icon, "_item"    , item    )
    rawset(icon, "set_image", set_icon)

    if item.icon then
        icon:set_image(item.icon)
    end

    item.set_icon = function (_,value) icon:set_image(value) end

    if data.icon_per_state == true then --TODO create an icon widget, see item/common.lua
        item:connect_signal("state::changed",function(i,d,st)
            if item._original_icon and data.icon_transformation then
                wibox.widget.imagebox.set_image(icon,data.icon_transformation(item._original_icon,data,item))
            end
        end)
    end

    return icon
end

-- Add [F1], [F2] ... to items
function module.setup_fkey(item,data)
    item.set_f_key = function(_,value)
        item._internal.has_changed = true
        item._internal.f_key = value
        data:remove_key_hook("F"..value)
        data:add_key_hook({}, "F"..value      , "press", function()
            item.button1(data)
            data.visible = false
        end)
        item:emit_signal("f_key::changed", value)
    end
    item.get_f_key = function() return item._internal.f_key end

    if item._internal.f_key then
        item:set_f_key(item._internal.f_key)
    end
end

-- Setup the checkbox
function module.setup_checked(item, data)
    if item.checkable then
        item.get_checked = function()
            if type(item._private_data.checked) == "function" then
                return item._private_data.checked(data,item)
            else
                return item._private_data.checked
            end
        end

        local ck = wibox.widget.checkbox(item.checked or false, {
            style = beautiful.menu_checkbox_style,
            color = beautiful.fg_normal
        })

        item.set_checked = function (_,value)
        item._private_data.checked = value
        ck.checked = value
        item._internal.has_changed = true
        end
    return ck
  end
end

-- Proxy all events to the parent
function module.setup_event(data,item,widget)
    widget = widget or item.widget

    -- Setup data signals
    widget:connect_signal("button::press",function(_,__,___,id,mod,geo)
        local mods_invert = {}
        for k,v in ipairs(mod) do
            mods_invert[v] = k
        end

        item.state[4] = true
        data:emit_signal("button::press",item,id,mods_invert,geo)
        item:emit_signal("button::press",data,id,mods_invert,geo)
    end)
    widget:connect_signal("button::release",function(wdg,__,___,id,mod,geo)
        local mods_invert = {}
        for k,v in ipairs(mod) do
            mods_invert[v] = k
        end
        item.state[4] = nil
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
end

return module

-- kate: space-indent on; indent-width 4; replace-tabs on;
