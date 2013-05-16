local setmetatable = setmetatable
local print = print
local color = require("gears.color")
local cairo     = require( "lgi"              ).cairo

local beautiful    = require( "beautiful"    )

local module = {}

local checkedI
local notcheckedI
local isinit      = false

local function init()
    local size = beautiful.menu_height or 16
    notcheckedI = cairo.ImageSurface(cairo.Format.ARGB32, size,size)
    checkedI    = cairo.ImageSurface(cairo.Format.ARGB32, size,size)
    local cr2         = cairo.Context(notcheckedI)
    local cr          = cairo.Context(checkedI)
    cr:set_operator(cairo.Operator.CLEAR)
    cr2:set_operator(cairo.Operator.CLEAR)
    cr:paint()
    cr2:paint()
    cr:set_operator(cairo.Operator.SOURCE)
    cr2:set_operator(cairo.Operator.SOURCE)
    local sp = 2.5
    local rs = size - (2*sp)
    cr:set_source(color(beautiful.fg_normal))
    cr2:set_source(color(beautiful.fg_normal))
    cr:set_line_width(2)
    cr2:set_line_width(2)
    cr:move_to( sp , sp );cr:line_to( rs , sp )
    cr:move_to( sp , sp );cr:line_to( sp , rs )
    cr:move_to( sp , rs );cr:line_to( rs , rs )
    cr:move_to( rs , sp );cr:line_to( rs , rs )
    cr:move_to( sp , sp );cr:line_to( rs , rs )
    cr:move_to( sp , rs );cr:line_to( rs , sp )
    cr:stroke()

    cr2:move_to(  sp , sp );cr2:line_to (rs , sp , beautiful.fg_normal )
    cr2:move_to(  sp , sp );cr2:line_to (sp , rs , beautiful.fg_normal )
    cr2:move_to(  sp , rs );cr2:line_to (rs , rs , beautiful.fg_normal )
    cr2:move_to(  rs , sp );cr2:line_to (rs , rs , beautiful.fg_normal )
    cr2:stroke()

    isinit = true
end

function module.checked()
    if not isinit then
        init()
    end
    return checkedI
end

function module.unchecked()
    if not isinit then
        init()
    end
    return notcheckedI
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
