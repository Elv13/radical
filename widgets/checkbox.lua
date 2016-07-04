---------------------------------------------------------------------------
-- A boolean display widget.
--
--@DOC_wibox_widget_defaults_checkobox_EXAMPLE@
-- @author Emmanuel Lepage Valle
-- @copyright 2012 Emmanuel Lepage Vallee
-- @release @AWESOME_VERSION@
-- @classmod wibox.widget.checkbox
---------------------------------------------------------------------------

local color     = require( "gears.color"       )
local base      = require( "wibox.widget.base" )
local beautiful = require( "beautiful"         )

local module = {}

local function default_checked(self, context, cr, width, height)
    local size = math.min(width, height)
    local sp = size*0.15
    local rs = size - (2*sp)

    cr:set_line_width(1)
--     cr:translate(1,1)
--     cr:set_antialias(1)
    cr:move_to( sp , sp );cr:line_to( rs , sp )
    cr:move_to( sp , sp );cr:line_to( sp , rs )
    cr:move_to( sp , rs );cr:line_to( rs , rs )
    cr:move_to( rs , sp );cr:line_to( rs , rs )
    cr:move_to( sp , sp );cr:line_to( rs , rs )
    cr:move_to( sp , rs );cr:line_to( rs , sp )
    cr:stroke()
end

local function default_unchecked(self, context, cr, width, height)
    local size = math.min(width, height)
    local sp = size*0.15
    local rs = size - (2*sp)

    cr:set_line_width(1)
--     cr:translate(1,1)
--     cr:set_antialias(1)
    cr:move_to(  sp , sp );cr:line_to (rs , sp )
    cr:move_to(  sp , sp );cr:line_to (sp , rs )
    cr:move_to(  sp , rs );cr:line_to (rs , rs )
    cr:move_to(  rs , sp );cr:line_to (rs , rs )
    cr:stroke()
end

local function holo_checked(self, context, cr, width, height)
    local size = math.min(width, height) - 2

    cr:arc(size/2+1,size/2+1,size/2,0,math.pi*2)
    cr:stroke()

    size = size*0.5

    cr:arc(size/2+5,size/2+5,size/2,0,math.pi*2)
    cr:fill()
end

local function holo_unchecked(self, context, cr, width, height)
    local size = math.min(width, height) - 2

    cr:arc(size/2+1,size/2+1,size/2,0,math.pi*2)
    cr:stroke()
end

local style = {
    holo    = holo,
    default = init,
}

local draw_f = {
    default = {
        [true ] = default_checked,
        [false] = default_unchecked,
    },
    holo = {
        [true ] = holo_checked,
        [false] = holo_unchecked,
    }
}

local function draw(self, context, cr, width, height)
    local col     = self._private.color
    local checked = self._private.checked
    local style   = self._private.style

    if col then
        cr:save()
        cr:set_source(col)
    end

    draw_f[style][checked](self, context, cr, width, height)

    if col then
        cr:restore()
    end
end

local function fit(box, context, w, h)
    local size = math.min(w, h)
    return size, size
end

--- If the checkbox is checked.
-- @property checked
-- @param boolean

local function get_checked(self)
    return self._private.checked
end

local function set_checked(self, value)
    self._private.checked = value or false

    self:emit_signal("widget::redraw_needed")
end

--- The default checkbox style.
-- @beautiful beautiful.checkbox_style
-- @tparam[opt="default"] string checkbox_style

--- The checkbox style.
-- @property style
-- @param string

local function get_style(self)
    return self._private.style
end

local function set_style(self, value)
    assert(type(value) == "string")
    assert(style[value])

    self._private.style = value
    self:emit_signal("widget::redraw_needed")
end

local function get_color(self)
    return self._private.color
end

local function set_color(self, value)
    self._private.color = color(value)

    self:emit_signal("widget::redraw_needed")
end

--- The checkbox color.
-- @property color

local function new(checked, args)
    checked, args = checked or false, args or {}

    local w = base.make_widget()
    w._private.style = args.style or beautiful.checkbox_style or "default"
    w._private.checked = checked
    w._private.color = args.color and color(args.color) or nil

    rawset(w, "fit" , fit )
    rawset(w, "draw", draw)

    return w
end

return setmetatable(module, { __call = function(_, ...) return new(...) end})

-- kate: space-indent on; indent-width 4; replace-tabs on;
