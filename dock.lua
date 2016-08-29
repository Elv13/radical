local setmetatable = setmetatable
local math = math
local base        = require( "radical.base"               )
local color       = require( "gears.color"                )
local wibox       = require( "wibox"                      )
local beautiful   = require( "beautiful"                  )
local vertical    = require( "radical.layout.vertical"    )
local horizontal  = require( "radical.layout.horizontal"  )
local item_layout = require( "radical.item.layout.icon"   )
local item_style  = require( "radical.item.style.rounded" )
local hot_corner  = require( "radical.hot_corner"         )
local shape       = require( "gears.shape"                )
local common      = require( "radical.common"             )
local smart_wibox = require( "radical.smart_wibox"        )
local aplace      = require( "awful.placement"            )
local timer       = require( "gears.timer"                )

local default_radius = 10
local rad = beautiful.dock_corner_radius or default_radius
local default_shape =  function(cr, width, height) shape.partially_rounded_rect(cr, width, height, false, true, true, false, rad) end

local capi,module = { mouse = mouse , screen = screen, keygrabber = keygrabber },{}
local max_size = {height={},width={}}

local docks = setmetatable({}, {__mode="k"})

-- Compute the optimal maxmimum size
local function get_max_size(data,screen)
    local dir = "left"
    local w_or_h = ((dir == "left" or dir == "right") and "height" or "width")
    local res = max_size[w_or_h][screen]

    if not res then
        local margin = beautiful.dock_margin or 52
        res = capi.screen[screen].workarea[w_or_h] - margin
        max_size[w_or_h][screen] = res
    end

    return res
end

--TODO it still works, but rewrite this code anyway
-- The dock always have to be shorter than the screen
local function adapt_size(data,w,h,screen)
    local max = get_max_size(data,screen)

    -- Get the number of items minus the number of widgets
    -- This can be used to approximate the number of pixel to remove
    local visible_item = data.visible_row_count

    local orientation = "vertical"

    if orientation == "vertical" and h > max then
        local wdg_height = data.widget_fit_height_sum
        --TODO this assume the widget size wont change

        data.item_height   = math.floor((max-wdg_height)/visible_item)
        data.item_width    = data.item_height
        data.default_width = data.item_width

    elseif orientation == "horizontal" and w > max then
        --TODO merge this with above
        data.item_width = math.floor((data.item_height*max)/w)
        h = data.item_width
        data.item_height  = h
    end
    if data.icon_size and data.icon_size > w then
        data.icon_size = w
    end

    data._internal.layout:emit_signal("widget::layout_changed")
    data._internal.layout:emit_signal("widget::redraw_needed" )
end

-- Create the main wibox (lazy-loading)
local function get_wibox(data, screen)
    if data._internal.w then return data._internal.w end

    data._internal.margin = wibox.container.margin(data._internal.layout)

    local w = smart_wibox(data._internal.margin, {
        screen             = screen                                         ,
        ontop              = not beautiful.dock_always_show                 ,
        shape              = beautiful.dock_shape or default_shape          ,
        shape_border_width = 1                                              ,
        shape_border_color = color(data.border_color or data.fg            ),
        bg                 = color(beautiful.bg_dock or beautiful.bg_normal),
        placement          = false                                          ,
        type               = "dock"                                         ,
    })


    data._internal.w = w

    data:emit_signal("visible::changed",true)

    w:connect_signal("property::height",function()
        adapt_size(data, w.width, w.height, 1)
    end)

    aplace.left(w, {
        attach          = true,
        update_workarea = beautiful.dock_always_show,
        honor_workarea  = false,
    })

    -- Make sure it is resized
    docks[screen] = docks[screen] or setmetatable({}, {__mode="v"})
    table.insert(docks[capi.screen[screen]], data)

    return w
end

local function new(args)
    args = args or {}
    local orientation = (not args.position or args.position == "left" or args.position == "right") and "vertical" or "horizontal"
    local length_inv  = orientation == "vertical" and "width" or "height"

    -- The the Radical arguments
    args.internal = args.internal or {}
    args.internal.orientation = orientation
    args.internal.setup_item     = args.internal.setup_item     or common.setup_item
    args.item_style              = args.item_style              or item_style
    args.bg                   = color("#00000000") --Use the dock bg instead
    args.item_height          = 40
    args.item_width           = 40
    args.sub_menu_on          = args.sub_menu_on or base.event.BUTTON1
    args.internal             = args.internal or {}
    args.internal.layout_func = orientation == "vertical" and vertical or horizontal
    args.layout               = args.layout or args.internal.layout_func
    args.item_style           = args.item_style
    args.item_layout          = args.item_layout or item_layout
    args.icon_per_state       = beautiful.dock_icon_per_state or args.icon_per_state or false
    args[length_inv]          = args[length_inv] or 40

    -- Create the dock
    local ret = base(args)
    ret.position = args.position or "left"
    ret.screen = args.screen or 1

    -- Add a 1px placeholder to trigger it
    if not beautiful.dock_always_show then
        hot_corner.register_wibox(ret.position, function()
            return get_wibox(ret, 1)
        end, ret.screen, 1)
    else
        timer.delayed_call(function()
            local w = get_wibox(ret, 1)
            w.visible = true
        end)
    end

    local internal = ret._internal

    -- Create the layout
    internal.layout = ret.layout(ret)

    -- Getters
    ret.get_visible = function() return true end
    ret.get_margins = common.get_margins

    function ret:set_visible(value)
        if internal.w then
            internal.w.visible = value or false
        end
    end

    common.setup_item_move_events(ret)

    return ret
end

-- Resize the docks when the stuts (wibars, docked client) change
capi.screen.connect_signal("property::workarea", function(s)
    docks[s] = docks[s] or setmetatable({}, {__mode="v"})

    for _, v in ipairs(docks[s]) do
       adapt_size(v, v._internal.w.width, v._internal.w.height, s)
    end
end)

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
