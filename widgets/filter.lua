local setmetatable = setmetatable
local print = print
local color = require("gears.color")
local cairo     = require( "lgi"              ).cairo
local wibox = require("wibox")

local beautiful    = require( "beautiful"    )

local module = {}

local function new(data)
  local filter_tb = wibox.widget.textbox()
  local bg = wibox.widget.background()
  bg:set_bg(data.bg_highlight)
  bg:set_widget(filter_tb)
  filter_tb:set_markup(" <b>".. data.filter_prefix .."</b> "..data.filter_placeholder)
  filter_tb.fit = function(tb,width,height)
    return width,data.item_height
  end
  filter_tb:set_underlay(data.filter_underlay,{alpha=data.filter_underlay_alpha,color=data.filter_underlay_color})
  data:connect_signal("filter_string::changed",function()
    local is_empty = data.filter_string == ""
    filter_tb:set_markup(" <b>".. data.filter_prefix .."</b> "..(is_empty and data.filter_placeholder or data.filter_string))
  end)
  bg.widget = filter_tb
  return bg
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
