local setmetatable = setmetatable
local wibox        = require( "wibox" )

local module = {}

local function left(data)
    data.next_item.selected = true
end

local function right(data)
    data.previous_item.selected = true
end

local function up(data)
    local idx,rc,col = data.current_index,data.rowcount,data.column
    idx = idx-col
    if idx <= 0 then
        idx = rc + idx + 1
    end
    data.items[idx].selected = true
end

local function down(data)
    local idx,rc,col = data.current_index,data.rowcount,data.column
    idx = idx+col
    if idx > rc then
        idx = idx - rc - 1
    end
    data.items[idx].selected = true
end

function module.setup_key_hooks(data)
    data:add_key_hook({}, "Up"      , "press", up    )
    data:add_key_hook({}, "Down"    , "press", down  )
    data:add_key_hook({}, "Left"    , "press", left  )
    data:add_key_hook({}, "Right"   , "press", right )
end

--Get preferred item geometry
local function item_fit(data,item,...)
    return data.item_height, data.item_height
end

local function new(data)
    return wibox.layout {
        column_count    = data.column,
        row_count       = data.row or (not data.column and 2 or nil),
        item_fit        = item_fit,
        setup_key_hooks = module.setup_key_hooks,
        layout          = wibox.layout.grid --FIXME this is monkeypatched
    }
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
