-- Gather common code that can be shared between multiple sub-systems to widgets
local item_mod = require( "radical.item"   )
local wibox    = require( "wibox"          )
local horizontal_item_layout = require( "radical.item.layout.horizontal" )
local margins2     = require( "radical.margins"     )

local module = {}

local function left(data)
    if data._current_item._tmp_menu then
        data = data._current_item._tmp_menu
        data.items[1].selected = true
        return true,data
    end
end

local function right(data)
    if data.parent_geometry and data.parent_geometry.is_menu then
        for k,v in ipairs(data.items) do
            if v._tmp_menu == data or v.sub_menu_m == data then
                v.selected = true
            end
        end
        data.visible = false
        data = data.parent_geometry
        return true,data
    else
        return false
    end
end

local function up(data)
    if not data.previous_item then return end
    data.previous_item.selected = true
end

local function down(data)
    if not data.next_item then return end
    data.next_item.selected = true
end

function module:setup_key_hooks(data)
    data:add_key_hook({}, "Up"      , "press", up    )
    data:add_key_hook({}, "Down"    , "press", down  )
    data:add_key_hook({}, "Left"    , "press", right )
    data:add_key_hook({}, "Right"   , "press", left  )
end

function module.get_margins(data)
    local internal = data._internal

    if not internal._margins then
        local ret = {
            left   = ((data.default_margins.left or data.default_margins.LEFT)
                        or (data.style and data.style.margins.LEFT   ) or 0),
            right  = ((data.default_margins.right or data.default_margins.RIGHT)
                        or (data.style and data.style.margins.RIGHT  ) or 0),
            top    = ((data.default_margins.top or data.default_margins.TOP)
                        or (data.style and data.style.margins.TOP    ) or 0),
            bottom = ((data.default_margins.bottom or data.default_margins.BOTTOM)
                        or (data.style and data.style.margins.BOTTOM ) or 0),
        }

        local m = margins2(internal.margin,ret)
        rawset(m,"_reset",m.reset)

        function m.reset(margins)
            m.defaults = ret
            m:_reset()
        end

        internal._margins = m
    end

    return internal._margins
end

function module.setup_buttons(data,item,args)
    local buttons = {}
    for i=1,10 do
        if args["button"..i] then
            buttons[i] = args["button"..i]
        end
    end

    -- Setup sub_menu
    if (item.sub_menu_m or item.sub_menu_f) and data.sub_menu_on >= item_mod.event.BUTTON1 and data.sub_menu_on <= item_mod.event.BUTTON3 then
        item.widget:set_menu(item.sub_menu_m or item.sub_menu_f,"button::pressed",data.sub_menu_on)
    end

    --Hide on right click
    if not buttons[3] then
        buttons[3] = function()
            data:hide()
        end
    end

    -- Scroll up
    if not buttons[4] then
        buttons[4] = function()
            data:scroll_up()
        end
    end

    -- Scroll down
    if not buttons[5] then
        buttons[5] = function()
            data:scroll_down()
        end
    end

    item:connect_signal("button::release",function(_m,_i,button_id,mods,geo)
        if #mods == 0 and buttons[button_id] then
            buttons[button_id](_m,_i,mods,geo)
        end
    end)
end

function module.setup_item_move_events(data)
    local internal = data._internal
    local l = internal.content_layout or internal.layout

    --SWAP / MOVE / REMOVE
    data:connect_signal("item::swapped",function(_,item1,item2,index1,index2)
        l:swap(index1, index2)
    end)

    data:connect_signal("item::moved",function(_,item,new_idx,old_idx)
        local w = l:get_children()[old_idx]
        l:remove(old_idx)
        l:insert(new_idx, w)
    end)

    data:connect_signal("item::removed",function(_,item,old_idx)
        l:remove(old_idx)
    end)

    data:connect_signal("item::appended",function(_,item)
        l:add(item.widget)
    end)

    data:connect_signal("item::added", function(_,item)
        l:add(item.widget)
    end)

    data:connect_signal("widget::added",function(_,item,widget)
        wibox.layout.fixed.add(l,item.widget)
        l:emit_signal("widget::updated")
    end)

    data:connect_signal("prefix_widget::added",function(_,widget,args)
        data._internal.pref_l:insert(1,widget)
    end)

    data:connect_signal("suffix_widget::added",function(_,widget,args)
        data._internal.suf_l:add(widget)
    end)

    data:connect_signal("clear::menu",function(_,vis)
        l:reset()
    end)

end

function module.setup_state_events(data, item)
    if data.select_on == item_mod.event.HOVER then
        item.widget:connect_signal("mouse::enter", function() item.selected = true end)
        item.widget:connect_signal("mouse::leave", function() item.selected = false end)
    else
        item.widget:connect_signal("mouse::enter", function() item.hover = true end)
        item.widget:connect_signal("mouse::leave", function() item.hover = false end)
    end
end

function module.setup_item(data,item,args)
    --Create the background
    local item_layout = item.layout or data.item_layout or horizontal_item_layout
    item_layout(item,data,args)

    -- Layout
    if data._internal.layout.setup_item then
        data._internal.layout.setup_item(data._internal.layout,data,item,args)
    end

    -- Buttons
    module.setup_buttons(data,item,args)

    -- Tooltip
    item.widget:set_tooltip(item.tooltip)

    -- Set the correct item state
    module.setup_state_events(data, item)

    -- Setup tooltip
    item.widget:set_tooltip(item.tooltip)

    -- Apply item style
    local item_style = item.item_style or data.item_style
    item_style(item,{})

    -- Enable scrollbar (if necessary)
    if data._internal.scroll_w and data.rowcount > data.max_items then
        data._internal.scroll_w.visible = true
        data._internal.scroll_w["up"]:emit_signal("widget::updated")
        data._internal.scroll_w["down"]:emit_signal("widget::updated")
    end

    -- Setup the infoshapes
    if item._internal.infoshapes then
        item.infoshapes = item._internal.infoshapes
    end

    -- Hide items after the maximum is reached
    if data.max_items ~= nil and data.rowcount > data.max_items then-- and (data._start_at or 0)
        item.widget:set_visible(false)
    end

    item.widget:emit_signal("widget::updated")
end

return module
-- kate: space-indent on; indent-width 4; replace-tabs on;
