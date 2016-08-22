local setmetatable = setmetatable
local base         = require( "radical.base"        )
local wibox        = require( "wibox"               )
local beautiful    = require( "beautiful"           )
local layout       = require( "radical.layout"      )
local arrow_style  = require( "radical.style.arrow" )
local smart_wibox  = require( "radical.smart_wibox" )
local common       = require( "radical.common"      )

local capi, module = { keygrabber = keygrabber },{}

local function set_visible(i, value)
    local w, pg = i.w, i.private_data.parent_geometry

    if value and pg then
        w:move_by_parent(pg, "widget")
    end

    w.visible = value

    if not value and (not pg or not pg.is_menu) then
        capi.keygrabber.stop()
    end
end

local function new(args)
    args                     = args or {}
    args.internal            = args.internal or {}
    args.internal.setup_item = args.internal.setup_item or common.setup_item
    args.style = args.style or beautiful.menu_default_style or arrow_style
    local data = base(args)

    data:connect_signal("parent_geometry::changed", function()
        args.internal.w:move_by_parent(data.parent_geometry, "widget")
    end)

    local internal = data._internal

    -- Create the layout
    data.layout = data.layout or layout.vertical

    internal.layout = data.layout(data)
    internal.margin = wibox.container.margin(internal.layout)

    -- Init
    internal.w = smart_wibox(internal.margin, {
        visible             = false              ,
        ontop               = true               ,
        opacity             = data.opacity       ,
        bg                  = data.bg            ,
        fg                  = data.fg            ,
        preferred_positions = {"right", "left"  },
        border_color        = data.border_color
                               or beautiful.menu_outline_color
                               or beautiful.menu_border_color
                               or beautiful.fg_normal
    })

    -- Accessors
    data.get_wibox       = function() return internal.w                    end
    data.get_visible     = function() return internal.private_data.visible end
    data.get_screen      = function() return internal.w.screen             end
    data.get_margins     = common.get_margins
    internal.set_visible = set_visible

    -- Support remove, swap, insert, append...
    common.setup_item_move_events(data)

    -- Init the style
    args.style(data)

    return data
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
