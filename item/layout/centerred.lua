local setmetatable = setmetatable
local beautiful  = require( "beautiful"    )
local color      = require( "gears.color"  )
local cairo      = require( "lgi"          ).cairo
local wibox      = require( "wibox"        )
local checkbox   = require( "radical.widgets.checkbox" )
local fkey       = require( "radical.widgets.fkey"         )
local horizontal = require( "radical.item.layout.horizontal" )

local module = {}

local function create_item(item,data,args)
  -- Background
  local bg = wibox.widget.background()

  -- Margins
  local m = wibox.layout.margin(la)
  m:set_margins (0)
  m:set_left  ( data.item_style.margins.LEFT   )
  m:set_right ( data.item_style.margins.RIGHT  )
  m:set_top   ( data.item_style.margins.TOP    )
  m:set_bottom( data.item_style.margins.BOTTOM )

  local text = wibox.widget.textbox()
  text:set_align("center")

  -- Layout
  local align = wibox.layout.align.horizontal()
  align:set_middle( text )
  m:set_widget(align)
  bg:set_widget(m)

  item._internal.text_w = text
  item._internal.icon_w = nil
  item._internal.margin_w = m

  -- Setup events
  horizontal.setup_event(data,item,bg)

  return bg
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
