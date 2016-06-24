local setmetatable = setmetatable
local wibox = require("wibox")

local beautiful    = require( "beautiful"    )

local module = {}

local function new(data,text,args)
  args = args or {}
  local bg = wibox.container.background()
  local infoHeader     = wibox.widget.textbox()
  infoHeader:set_font("")
  infoHeader:set_markup( " <span color='".. beautiful.bg_normal .."' font='DejaVu Sans Mono' size='small' font_weight='bold'>".. text .."</span> " )
  local l = wibox.layout.align.horizontal()
  l:set_left(infoHeader)
  bg:set_widget(l)
  bg:set_bg(data.bg_header)
  if args.suffix_widget then
    l:set_right(args.suffix_widget)
  end
  return bg
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
