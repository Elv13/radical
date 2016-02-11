local setmetatable = setmetatable
local print = print
local color      = require( "gears.color"   )
local cairo      = require( "lgi"           ).cairo
local wibox      = require( "wibox"         )
local util       = require( "awful.util"    )
local button     = require( "awful.button"  )
local beautiful  = require( "beautiful"     )
local shape      = require( "gears.shape"   )
local surface    = require( "gears.surface" )

local module = {}

local arr_up,arr_down
local isinit = false

local function init()
    if isinit then return end

    arr_down = surface.load_from_shape(10, 10,
        shape.transform(shape.isosceles_triangle) : scale(1, 0.5) : rotate_at(5,5, math.pi) : translate(0,5),
        beautiful.fg_normal
    )
    arr_up = surface.load_from_shape(10, 10,
        shape.transform(shape.isosceles_triangle) : scale(1, 0.5) : translate(0,5),
        beautiful.fg_normal
    )

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
  scroll_w.visible = false
  for k,v in ipairs({"up","down"}) do
    local ib = wibox.widget.imagebox()
    ib:set_image(module[v]())
    ib.fit = function(tb,context,width,height)
      if scroll_w.visible == false then
        return 0,0
      end
      return width,data.item_height
    end
    ib.draw = function(self, context, cr, width, height)
      if width > 0 and height > 0 then
        cr:set_source_surface(self._image, width/2 - self._image:get_width()/2, 0)
      end
      cr:paint()
    end
    scroll_w[v] = wibox.widget.background()
    scroll_w[v]:set_widget(ib)
    scroll_w[v].visible = true
    data.item_style({widget=scroll_w[v]},{color=data.bg_highlight})
    scroll_w[v]:connect_signal("mouse::enter",function()
      data.item_style({widget=scroll_w[v]},{color=data.bg_alternate or beautiful.bg_focus})
    end)
    scroll_w[v]:connect_signal("mouse::leave",function()
      data.item_style({widget=scroll_w[v]},{color=data.bg_highlight})
    end)
    scroll_w[v]:buttons( util.table.join( button({ }, 1, function()
      data["scroll_"..v](data)
    end) ))
  end
  return scroll_w
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
