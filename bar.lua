local setmetatable,unpack,table = setmetatable,unpack,table
local base       = require( "radical.base"                    )
local color      = require( "gears.color"                     )
local wibox      = require( "wibox"                           )
local beautiful  = require( "beautiful"                       )
local item_style = require( "radical.item.style.arrow_single" )
local item_layout= require( "radical.item.layout.horizontal"  )
local common     = require( "radical.common"                  )

local module = {}

local function setup_drawable(data)
    local internal = data._internal

    internal.layout       = internal.layout_func or wibox.layout.fixed.horizontal()
    internal.margin       = wibox.layout.margin(internal.layout)
    internal.layout._data = data

    if internal.layout.set_spacing and data.spacing then
        internal.layout:set_spacing(data.spacing)
    end

    --Getters
    data.get_visible = function() return true end
    data.get_margins = common.get_margins

    if data.style then
        data.style(data)
    end

    common.setup_item_move_events(data)
end

local function new(args)
    local args                   = args                         or {}
    args.internal                = args.internal                or {}
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item     or common.setup_item
    args.item_style              = args.item_style              or item_style
    args.item_layout             = args.item_layout             or item_layout
    args.sub_menu_on             = args.sub_menu_on             or base.event.BUTTON1

    local ret = base(args)

    return ret,ret._internal.margin
end

function module.flex(args)
    local args                = args          or {}
    args.internal             = args.internal or {}
    args.internal.layout_func = wibox.layout.flex.horizontal()

    local data = new(args)

    function data._internal.text_fit(self,width,height) return width,height end

    return data,data._internal.margin
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
