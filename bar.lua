local setmetatable = setmetatable
local base       = require( "radical.base"                    )
local wibox      = require( "wibox"                           )
local item_style = require( "radical.item.style.arrow_single" )
local item_layout= require( "radical.item.layout.horizontal"  )
local common     = require( "radical.common"                  )
local shape      = require( "gears.shape"                     )

local module = {}

local function new(args)
    args                         = args                         or {}
    args.border_width            = args.border_width            or 0
    args.internal                = args.internal                or {}
    args.internal.setup_item     = args.internal.setup_item     or common.setup_item
    args.item_style              = args.item_style              or item_style
    args.item_layout             = args.item_layout             or item_layout
    args.sub_menu_on             = args.sub_menu_on             or base.event.BUTTON1

    local data = base(args)

    local internal = data._internal

    -- Use a background to make the border work
    internal.widget = wibox.widget.base.make_widget_declarative {
        {
            {
                id      = "main_layout"      ,
                spacing = data.spacing or nil,
                _data   = data               ,
                layout  = internal.layout_func or wibox.layout.fixed.horizontal
            },
            id     = "main_margin"      ,
            layout = wibox.container.margin,
        },
        shape              = data.shape or shape.rectangle or nil,
        shape_border_width = data.border_width                   ,
        shape_border_color = data.border_color                   ,
        widget             = wibox.container.background             ,
    }
    internal.layout       = internal.widget:get_children_by_id("main_layout")[1]
    internal.margin       = internal.widget:get_children_by_id("main_margin")[1]

    --Getters
    data.get_visible = function() return true end
    data.get_margins = common.get_margins

    function data.get_widget()
        return internal.widget
    end

    data:get_margins()

    if data.style then
        data.style(data)
    end

    common.setup_item_move_events(data)

    return data, data._internal.widget
end

function module.flex(args)
    args                      = args          or {}
    args.internal             = args.internal or {}
    args.internal.layout_func = wibox.layout.flex.horizontal()

    local data = new(args)

    return data,data._internal.margin
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
