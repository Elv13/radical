local setmetatable = setmetatable
local color        = require( "gears.color" )
local cairo        = require( "lgi"         ).cairo
local pango        = require( "lgi"         ).Pango
local pangocairo   = require( "lgi"         ).PangoCairo
local wibox        = require( "wibox"       )
local beautiful    = require( "beautiful"   )
local constrainedtext = require("radical.widgets.constrainedtext")
local shape = require("gears.shape")

local function new(data,item)
    local pref = wibox.widget {
        {
            {
                {
                    padding        = 1,
                    width_for_text = "F99",
                    text           = item._internal.f_key or "F1",
                    widget         = constrainedtext,
                    id             = "textbox",
                },
                left   = data.item_height / 2 - 2*2,
                right  = data.item_height / 2 - 2*2,
                widget = wibox.container.margin
            },
            shape  = shape.rounded_bar,
            bg     = color(beautiful.fg_normal),
            fg     = color(beautiful.bg_normal),
            widget = wibox.container.background
        },
        margins = 2,
        widget = wibox.container.margin
    }

    local tb = pref:get_children_by_id("textbox")[1]
    assert(tb)

    item:connect_signal("f_key::changed" , function()
        tb:set_text("F"..item._internal.f_key)
    end)

    return pref
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
