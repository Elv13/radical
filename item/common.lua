local wibox        = require( "wibox"                      )

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
    icon._data = data
    icon._item = item
    icon.set_image = set_icon
    if item.icon then
        icon:set_image(item.icon)
    end

    item.set_icon = function (_,value) icon:set_image(value) end

    return icon
end

-- Add [F1], [F2] ... to items
function module.setup_fkey(item,data)
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

-- Proxy all events to the parent
function module.setup_event(data,item,widget)
    local widget = widget or item.widget

    -- Setup data signals
    widget:connect_signal("button::press",function(_,__,___,id,mod,geo)
        local mods_invert = {}
        for k,v in ipairs(mod) do
            mods_invert[v] = i
        end

        item.state[4] = true
        data:emit_signal("button::press",item,id,mods_invert,geo)
        item:emit_signal("button::press",data,id,mods_invert,geo)
    end)
    widget:connect_signal("button::release",function(wdg,__,___,id,mod,geo)
        local mods_invert = {}
        for k,v in ipairs(mod) do
            mods_invert[v] = i
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
