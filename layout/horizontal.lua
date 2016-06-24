local setmetatable = setmetatable
local wibox        = require( "wibox"          )
local common       = require( "radical.common" )

local module = {}

function module:setup_item(data,item,args)
    -- Compute the minimum width
    if data.auto_resize then --FIXME this wont work if thext change
        local _, fit_h = item._internal.margin_w:get_preferred_size()

        if not data._internal.largest_item_h_v or data._internal.largest_item_h_v < fit_h then
            data._internal.largest_item_h   = item
            data._internal.largest_item_h_v = fit_h
        end
    end
    item:set_text(item._private_data.text)
end

--Get preferred item geometry
local function item_fit(data,item,self, context, width, height)
    local w, h = item._private_data._fit(self,context,width,height) --TODO port to new context API

    return data.item_width or w, h --TODO broken
end

local function new(data)

    -- Define the item layout
    local real_l = wibox.widget.base.make_widget_declarative {
        spacing         = data.spacing                 ,
        item_fit        = item_fit                     ,
        setup_key_hooks = common.setup_key_hooks       ,
        setup_item      = module.setup_item            ,
        layout          = wibox.layout.fixed.horizontal,
    }

    -- Hack fit
    function real_l.fit(self,context)
        local w,h
        if data.auto_resize and data._internal.largest_item_h then
            w,h = data.rowcount*(data.item_width or data.default_width),data._internal.largest_item_h_v > data.item_height and data._internal.largest_item_h_v or data.item_height
        else
            w,h = data.rowcount*(data.item_width or data.default_width),data.item_height
        end

        return w,h
    end

    return real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
