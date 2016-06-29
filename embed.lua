local setmetatable  = setmetatable
local base          = require( "radical.base"          )
local layout        = require( "radical.layout"        )
local classic_style = require( "radical.style.classic" )
local common        = require( "radical.common"        )

local function new(args)
    args = args or {}
    args.internal = args.internal or {}
    args.internal.setup_item     = args.internal.setup_item or common.setup_item
    args.style = args.style or classic_style
    local data = base(args)

    data:connect_signal("clear::menu",function(_,vis)
        local l = data._internal.content_layout or data._internal.layout
        l:reset()
    end)

    local internal = data._internal

    -- An embeded menu can only be visible if the parent is
    data.get_visible = function() return data._embeded_parent and data._embeded_parent.visible or false end
    data.set_visible = function(_,v) if data._embeded_parent then data._embeded_parent.visible = v end end

    local l = data.layout or layout.vertical
    internal.layout = l(data)

    data.margins = {left=0,right=0,bottom=0,top=0}

    internal.layout:connect_signal("mouse::enter",function(_,geo)
        if data._embeded_parent._current_item then
            data._embeded_parent._current_item.selected = false
        end
    end)

    internal.layout:connect_signal("mouse::leave",function(_,geo)
        if data._current_item then
            data._current_item.selected = false
        end
    end)

    -- Support remove, swap, insert, append...
    common.setup_item_move_events(data)

    return data
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
