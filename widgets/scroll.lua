local setmetatable = setmetatable
local print = print
local color = require("gears.color")
local cairo     = require( "lgi"              ).cairo
local wibox = require("wibox")

local beautiful    = require( "beautiful"    )

local module = {}

local arr_up
local arr_down
local isinit      = false

local function init()
    local size = beautiful.menu_height or 16
    arr_down = cairo.ImageSurface(cairo.Format.ARGB32, size,size)
    arr_up    = cairo.ImageSurface(cairo.Format.ARGB32, size,size)
    local cr2         = cairo.Context(arr_down)
    local cr          = cairo.Context(arr_up)
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

function module.up()
    if not isinit then
        init()
    end
    return arr_up
end

function module.down()
    if not isinit then
        init()
    end
    return arr_down
end

local function new(data)
  local scroll_w = {}
  for k,v in ipairs({"up","down"}) do
    local ib = wibox.widget.imagebox()
    ib:set_image(module[v]())
    ib.fit = function(tb,width,height)
      return width,data.item_height
    end
    ib.draw = function(self,wibox, cr, width, height)
      cr:set_source_surface(self._image, width/2 - self._image:get_width()/2, 0)
      cr:paint()
    end
    scroll_w[v] = wibox.widget.background()
    scroll_w[v]:set_widget(ib)
    scroll_w[v].visible = true
    data.item_style(data,{widget=scroll_w[v]},false,false,true)
  end
  return scroll_w
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
