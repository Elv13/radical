---------------------------------------------------------------------------
--- A rather hacky way to create free-floating widgets.
--
-- Hopefully this will be more maintainable then the old Radical hard-coded
-- positioning code.
--
-- @author Emmanuel Lepage Vallee
-- @copyright 2016 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @module radical.smart_wibox
---------------------------------------------------------------------------
local capi      = {mouse = mouse, screen = screen}
local wibox     = require( "wibox"            )
local util      = require( "awful.util"       )
local surface   = require( "gears.surface"    )
local glib      = require( "lgi"              ).GLib
local beautiful = require( "beautiful"        )
local color     = require( "gears.color"      )
local screen    = require( "awful.screen"     )
local mouse     = require( "awful.mouse"      )
local placement = require( "radical.placement")
local unpack    = unpack or table.unpack

local module = {}

local main_widget = {}

--TODO position = relative to parent
--TODO direction = up or down (the alternate stuff)

-- Get the optimal direction for the wibox
-- This (try to) avoid going offscreen
local function set_position(self)
    local points = rawget(self, "possible_positions") or {}
    local preferred_positions = rawget(self, "_preferred_directions") or {}

    local pos_name = placement.move_relative(self, points, preferred_positions)

    if pos_name ~= rawget(self, "position") then
        self:emit_signal("property::direction", pos_name)
        rawset(self, "position", pos_name)
    end
end

--- Fit this widget into the given area
function main_widget:fit(context, width, height)
    if not self.widget then
        return 0, 0
    end

    return wibox.widget.base.fit_widget(self, context, self.widget, width, height)
end

--- Layout this widget
function main_widget:layout(context, width, height)
    if self.widget then
        local w, h = wibox.widget.base.fit_widget(self, context, self.widget, 9999, 9999)
        glib.idle_add(glib.PRIORITY_HIGH_IDLE, function()
            self._wb.width  = math.ceil(w or 1)
            self._wb.height = math.ceil(h or 1)
            set_position(self._wb)
        end)
        return { wibox.widget.base.place_widget_at(self.widget, 0, 0, width, height) }
    end
end

--- Set the widget that is drawn on top of the background
function main_widget:set_widget(widget)
    if widget then
        wibox.widget.base.check_widget(widget)
    end
    self.widget = widget
    self:emit_signal("widget::layout_changed")
end

--- Get the number of children element
-- @treturn table The children
function main_widget:get_children()
    return {self.widget}
end

--- Replace the layout children
-- This layout only accept one children, all others will be ignored
-- @tparam table children A table composed of valid widgets
function main_widget:set_children(children)
    self.widget = children and children[1]
    self:emit_signal("widget::layout_changed")
end

function main_widget:before_draw_children(context, cr, width, height)
    -- Update the wibox shape bounding. This module use custom painter instead
    -- of a shape clip to get antialiasing.
    if self._wb._shape and (width ~= self.prev_width or height ~= self.prev_height) then
        surface.apply_shape_bounding(self._wb, self._wb._shape, unpack(self._wb._shape_args))
        self.prev_width  = width
        self.prev_height = height
    end

    -- There is nothing else to do. The wibox background painter will do
end

-- Draw the border after the content to emulate the shape_clip
function main_widget:after_draw_children(context, cr, width, height)
    local border_width = self._wb._shape_border_width

    if not border_width then return end

    cr:translate(border_width/2, border_width/2)
    cr:set_line_width(border_width)

    cr:set_source(self._wb._shape_border_color)
    self._wb._shape(cr, width-border_width, height-border_width, unpack(self._wb._shape_args or {}))
    cr:stroke()
end

local wb_func = {}

--- Set the wibox shape.
-- All other paramaters will be passed to the `s` function
-- @param s A `gears.shape` compatible function
function wb_func:set_shape(s, ...)

    rawset(self, "_shape"          , s     )
    rawset(self, "_shape_args"     , {...} )

    self.widget:emit_signal("widget::layout_changed")
end

--- Set the wibox shape border color.
-- Note that this is independant from the wibox border_color.
-- The default are `beautiful.menu_border_color` or `beautiful.border_color`.
-- The there is no border, then this function will do nothing.
-- @param The border color or nil
function wb_func:set_shape_border_color(col)
    rawset(self,"_shape_border_color", col and color(col) or color(beautiful.menu_border_color or beautiful.border_color))
    self.widget:emit_signal("widget::layout_changed")
end

--- Set the shape border (clip) width.
-- The shape will be used to draw the border. Any content within the border
-- will be hidden.
-- @tparam number width The border width
function wb_func:set_shape_border_width(width)
    rawset(self,"_shape_border_width", width)
    self.widget:emit_signal("widget::layout_changed")
end

--- Set the preferred wibox directions relative to its parent.
-- Valid directions are:
-- * left
-- * right
-- * top
-- * bottom
-- @tparam string ... One of more directions (in the preferred order)
function wb_func:set_preferred_positions(...)
    local dirs = {}
    for k, v in ipairs{...} do
        dirs[v] = k
    end
    rawset(self, "_preferred_directions", dirs)
end

--- Move the wibox to a position relative to `geo`.
-- This will try to avoid overlapping the source wibox and auto-detect the right
-- direction to avoid going off-screen.
-- @param[opt=mouse.coords()] geo A geometry table. It is given as parameter
--  from buttons callbacks and signals such as `mouse::enter`.
-- @param mode Use the mouse position instead of the widget center as
-- reference point.
function wb_func:move_by_parent(geo, mode)
    if rawget(self, "is_relative") == false then return end

    --TODO add border_width?
    local dps = placement.get_relative_points(geo, mode, {
        xoffset = rawget(self, "xoffset") or 0,
        yoffset = rawget(self, "yoffset") or 0,
    })

    rawset(self, "possible_positions", dps)

    set_position(self)
end

function wb_func:move_by_mouse()
    --TODO
end

function wb_func:set_xoffset(offset)
    local old =  rawget(self, "xoffset") or 0
    if old == offset then return end

    rawset(self, "xoffset", offset)

    -- Update the points
    for k,v in pairs(rawget(self, "possible_positions") or {}) do
        v.x = v.x - old + offset
    end

    -- Update the position
    set_position(self)
end

function wb_func:set_yoffset(offset)
    local old =  rawget(self, "yoffset") or 0
    if old == offset then return end

    rawset(self, "yoffset", offset)

    -- Update the points
    for k,v in pairs(rawget(self, "possible_positions") or {}) do
        v.y = v.y - old + offset
    end

    -- Update the position
    set_position(self)
end

function wb_func:set_margin(margin)
    rawset(self, "left_margin"  , margin)
    rawset(self, "right_margin" , margin)
    rawset(self, "top_margin"   , margin)
    rawset(self, "bottom_margin", margin)
end

--- Set if the wibox take into account the other wiboxes.
-- @tparam boolean val Take the other wiboxes position into account
function wb_func:set_relative(val)
    rawset(self, "is_relative", val)
end

--- A brilliant idea to totally turn the whole hierarchy on its head
-- and create a widget that own a wibox...
local function create_auto_resize_widget(self, wdg, args)
    assert(wdg)
    local ii = wibox.widget.base.make_widget()
    util.table.crush(ii, main_widget)

    ii:set_widget(wdg)

    -- Create a wibox to host the widget
    local w = wibox(args or {})

    -- Wibox use metatable inheritance, rawset is necessary
    for k, v in pairs(wb_func) do
        rawset(w, k, v)
    end

    -- Cross-link the wibox and widget
    ii._wb = w
    w:set_widget(ii)
    rawset(w, "widget", wdg)

    -- Changing the widget is not supported
    rawset(w, "set_widget", function()end)

    w:set_shape_border_color()

    w:add_signal("property::direction")

    if args and args.preferred_positions then
        if type(args.preferred_positions) == "table" then
            w:set_preferred_positions(unpack(args.preferred_positions))
        else
            w:set_preferred_positions(args.preferred_positions)
        end
    end

    if args.shape then
        w:set_shape(args.shape, unpack(args.shape_args or {}))
    end

    if args.relative ~= nil then
        w:set_relative(args.relative)
    end

    for k,v in ipairs{"shape_border_color", "shape_border_width"} do
        if args[v] then
            w["set_"..v](w, args[v])
        end
    end

    return w
end

return setmetatable(module, {__call = create_auto_resize_widget})
