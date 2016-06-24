local setmetatable = setmetatable
local wibox      = require( "wibox"               )
local util       = require( "awful.util"          )
local margins2   = require( "radical.margins"     )
local common     = require( "radical.item.common" )

local function create_item(item,data,args)

    -- Define the item layout
    local w = wibox.widget.base.make_widget_declarative {
        {
            {
                nil,
                {
                    id     = "main_text"         ,
                    align  = "center"            ,
                    widget = wibox.widget.textbox,
                },
                nil,
                layout = wibox.layout.align.horizontal,
            },
            id     = "main_margin",
            layout = wibox.container.margin
        },
        widget = wibox.container.background,
    }
    item.widget             = w
    item._internal.margin_w = item.widget:get_children_by_id("main_margin")[1]
    item._internal.text_w   = item.widget:get_children_by_id("main_text"  )[1]

    -- Margins
    local mrgns = margins2(
        item._internal.margin_w,
        util.table.join(data.item_style.margins,data.default_item_margins)
    )

    function item:get_margins()
        return mrgns
    end

    -- Setup events
    common.setup_event(data, item, w)

    return w
end

return setmetatable({}, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
