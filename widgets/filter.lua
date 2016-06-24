local setmetatable = setmetatable
local wibox        = require("wibox")
local infoshapes   = require( "radical.widgets.infoshapes" )

local module = {}

local function set_data(self, data)
    local info = self:get_children_by_id("infoshapes" )[1]
    local tb   = self:get_children_by_id("filter_text")[1]

    function self.fit(_,context,width,height)
        return width,data.item_height
    end

    self:set_bg(data.bg_highlight)

    tb:set_markup(" <b>".. data.filter_prefix .."</b> "..data.filter_placeholder)

    info:add_infoshape {
        text  = data.filter_underlay      ,
        alpha = data.filter_underlay_alpha,
        color = data.filter_underlay_color,
    }

    data:connect_signal("filter_string::changed",function()
        local is_empty = data.filter_string == ""
        tb:set_markup(" <b>".. data.filter_prefix .."</b> "..(is_empty and data.filter_placeholder or data.filter_string))
    end)

    self:set_widget(info) --FIXME there is a bug somewhere

end

local function new(data)
    return wibox.widget.base.make_widget_declarative {
        {
            {
                id     = "filter_text",
                widget = wibox.widget.textbox
            },
            id     = "infoshapes",
            widget = infoshapes  ,
        },
        set_data = set_data,
        widget   = wibox.container.background
    }
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
