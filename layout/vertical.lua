local setmetatable = setmetatable
local scroll = require( "radical.widgets.scroll" )
local filter = require( "radical.widgets.filter" )
local wibox  = require( "wibox"                  )
local common = require( "radical.common"         )

local module = {}

--Get preferred item geometry
local function item_fit(data,item,self,context, width,height)
    local w, h = item._private_data._fit(self,context,width,height)
    return w, item.height or h --TODO use a constraint widget
end

function module:setup_item(data,item,args)
    item._private_data._fit = wibox.container.background.fit

    if not item._internal.margin_w then return end

    item._internal.margin_w.fit = function(...) return item_fit(data,item,...) end

    -- Compute the minimum width
    if data.auto_resize then --FIXME this wont work if the text change
        local fit_w = item._internal.margin_w:get_preferred_size()

        if fit_w < 1000 and (not data._internal.largest_item_w_v or data._internal.largest_item_w_v < fit_w) then
            data._internal.largest_item_w = item
            data._internal.largest_item_w_v = fit_w
        end
    end

end

local function compute_geo(data,width,height,force_values)
    local w = data.default_width
    if data.auto_resize and data._internal.largest_item_w then
        w = data._internal.largest_item_w_v > data.default_width and data._internal.largest_item_w_v or data.default_width
    end

    local visblerow = data.visible_row_count

    local _,sh = data._internal.suf_l:get_preferred_size()
    local _,ph = data._internal.pref_l:get_preferred_size()

    if not data._internal.has_widget then
        return w, visblerow*data.item_height + ph + sh
    else
        local sumh = data.widget_fit_height_sum
        local h = visblerow*data.item_height + sumh
        return w,h
    end
end

local function new(data)

    local function real_fit(self,context,o_w,o_h,force_values)
        return compute_geo(data,o_w,o_h,force_values)
    end

    -- Create the scroll widgets
    if data.max_items then
        data._internal.scroll_w = scroll(data)
    end

    -- Define the item layout
    local real_l = wibox.widget.base.make_widget_declarative {
        -- Widgets
        {
            -- The prefix section, used for the scroll widgets and custom prefixes

            -- Widgets
            data._internal.scroll_w and data._internal.scroll_w["up"] or nil,

            -- Attributes
            id     = "prefix_layout",
            layout = wibox.layout.fixed.vertical
        },
        {
            -- The main layout (where items are added)

            -- Attributes
            id      = "content_layout",
            spacing = data.spacing and data.spacing or 0,
            layout  = wibox.layout.fixed.vertical       ,
        },
        {
            -- The suffix section, used for the scroll widgets and custom suffixes

            -- Widgets
            data._internal.scroll_w and data._internal.scroll_w["down"] or nil,
            data.show_filter and {
                id     = "filter_widget",
                data   = data,
                widget = filter
            } or nil,

            -- Attributes
            id     = "suffix_layout"            ,
            layout = wibox.layout.fixed.vertical,
        },

        -- Attributes
        layout          = wibox.layout.fixed.vertical,

        -- Methods
        item_fit        = item_fit              ,
        setup_key_hooks = common.setup_key_hooks,
        setup_item      = module.setup_item     ,
    }

    -- Set the important widgets
    data._internal.content_layout = real_l:get_children_by_id( "content_layout" )[1]
    data._internal.suf_l          = real_l:get_children_by_id( "suffix_layout"  )[1]
    data._internal.pref_l         = real_l:get_children_by_id( "prefix_layout"  )[1]

    -- Set the overloaded methods
    real_l.fit = real_fit

    return real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
