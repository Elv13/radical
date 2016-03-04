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

    if value then
        w:move_by_parent(pg, true)
    end

    w.visible = value

    if not value and (not pg or not pg.is_menu) then
        capi.keygrabber.stop()
    end
end

local function setup_drawable(data)
    local internal = data._internal

    -- Create the layout
    data.layout = data.layout or layout.vertical

    internal.layout = data.layout(data)
    internal.margin = wibox.layout.margin(internal.layout)

    -- Init
    internal.w = smart_wibox(internal.margin, {
        visible             = false              ,
        ontop               = true               ,
        opacity             = data.opacity       ,
        bg                  = data.bg            ,
        fg                  = data.fg            ,
        preferred_positions = {"right", "bottom"},
        border_color        = data.border_color
                               or beautiful.menu_outline_color
                               or beautiful.menu_border_color
                               or beautiful.fg_normal
    })

    -- Accessors
    data.get_wibox       = function() return internal.w                    end
    data.get_visible     = function() return internal.private_data.visible end
    data.get_margins     = common.get_margins
    internal.set_visible = set_visible


    -- Support remove, swap, insert, append...
    common.setup_item_move_events(data)
end

local function new(args)
    local args                   = args or {}
    args.internal                = args.internal or {}
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item or common.setup_item
    args.style = args.style or beautiful.menu_default_style or arrow_style
    local ret = base(args)

    ret:connect_signal("parent_geometry::changed", function()
        args.internal.w:move_by_parent(ret.parent_geometry, true)
    end)

    -- Init the style
    args.style(ret)

    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
