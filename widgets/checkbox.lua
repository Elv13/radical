local setmetatable = setmetatable
local color     = require("gears.color")
local cairo     = require("lgi").cairo
local beautiful = require("beautiful")

local module = {}

local checkedI
local notcheckedI
local isinit = false

-- Default checkbox style
local function default()
    local size      = beautiful.menu_height or 16
    local x_padding = 3
    local sp = size * (beautiful.menu_checkbox_padding or 0.08)
    local rs = size - (2 * sp)

    notcheckedI = cairo.ImageSurface(cairo.Format.ARGB32, size, size)
    checkedI    = cairo.ImageSurface(cairo.Format.ARGB32, size, size)

    -- Checked
    local cr = cairo.Context(checkedI)
    cr:set_operator(cairo.Operator.CLEAR)
    cr:paint()
    cr:set_operator(cairo.Operator.SOURCE)

    cr:set_line_width(1)
    cr:set_source(color(beautiful.menu_checkbox_color or beautiful.fg_normal))
    cr:move_to(sp, sp);cr:line_to(rs, sp)
    cr:move_to(sp, sp);cr:line_to(sp, rs)
    cr:move_to(sp, rs);cr:line_to(rs, rs)
    cr:move_to(rs, sp);cr:line_to(rs, rs)
    cr:stroke()

    cr:set_line_width(2)
    cr:set_source(color(beautiful.menu_checkbox_checked_color or beautiful.fg_normal))
    cr:move_to(sp + x_padding, sp + x_padding);cr:line_to(rs - x_padding, rs - x_padding)
    cr:move_to(sp + x_padding, rs - x_padding);cr:line_to(rs - x_padding, sp + x_padding)
    cr:stroke()

    -- Unchecked
    local cr2 = cairo.Context(notcheckedI)
    cr2:set_operator(cairo.Operator.CLEAR)
    cr2:paint()
    cr2:set_operator(cairo.Operator.SOURCE)

    cr2:set_line_width(1)
    cr2:set_source(color(beautiful.menu_checkbox_color or beautiful.fg_normal))
    cr2:move_to(sp, sp);cr2:line_to(rs, sp)
    cr2:move_to(sp, sp);cr2:line_to(sp, rs)
    cr2:move_to(sp, rs);cr2:line_to(rs, rs)
    cr2:move_to(rs, sp);cr2:line_to(rs, rs)
    cr2:stroke()

    isinit = true
end

-- Holo checkbox style
local function holo()
    local size      = (beautiful.menu_height or 16)
    local x_padding = 3
    local padding   = size * (beautiful.menu_checkbox_padding or 0.08)

    notcheckedI = cairo.ImageSurface(cairo.Format.ARGB32, size, size)
    checkedI    = cairo.ImageSurface(cairo.Format.ARGB32, size, size)

    size = (size-(2*padding))/2

    -- Unchecked
    local cr2  = cairo.Context(notcheckedI)
    cr2:set_operator(cairo.Operator.CLEAR)
    cr2:paint()
    cr2:set_operator(cairo.Operator.SOURCE)

    cr2:set_source(color(beautiful.menu_checkbox_color or beautiful.fg_normal))
    cr2:set_line_width(1)
    cr2:arc(size+1, size+1, size, 0, math.pi*2)
    cr2:stroke()

    -- Checked
    local cr = cairo.Context(checkedI)
    cr:set_operator(cairo.Operator.CLEAR)
    cr:paint()
    cr:set_operator(cairo.Operator.SOURCE)
    
    cr:set_line_width(1)
    cr:set_source(color(beautiful.menu_checkbox_color or beautiful.fg_normal))
    cr:arc(size+1, size+1, size, 0, math.pi*2)
    cr:stroke()

    cr:set_source(color(beautiful.menu_checkbox_checked_color or beautiful.fg_normal))
    cr:arc(size+1, size+1, size-x_padding, 0, math.pi*2)
    cr:fill()

    isinit = true
end

local style = {
    holo    = holo,
    default = default,
}

function module.checked()
    if not isinit then
        style[beautiful.menu_checkbox_style or "default"]()
    end

    return checkedI
end

function module.unchecked()
    if not isinit then
        style[beautiful.menu_checkbox_style or "default"]()
    end

    return notcheckedI
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
