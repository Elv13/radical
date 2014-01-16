local setmetatable = setmetatable
local print = print
local debug=debug
local ipairs =  ipairs
local math = math
local base      = require( "radical.base"     )
local beautiful = require("beautiful")
local color = require("gears.color")
local cairo = require("lgi").cairo
local wibox = require("wibox")
-- local arrow_alt = require("radical.item_style.arrow_alt")

local module = {
  margins = {
    TOP    = 0,
    BOTTOM = 0,
    RIGHT  = 20,
    LEFT   = 3
  }
}

local function prefix_draw(self, w, cr, width, height)
  print("Hello",width,height,self)
  cr:save()
  cr:set_source_rgba(1,0,0,1)
  cr:rectangle(0,0,width+30,height)
  cr:fill()
  cr:restore()
  self._draw(self, w, cr, width, height)
end

local function prefix_fit(box,w,h)
  local width,height = box._fit(box,w,h)
  print("in fit",width,width+30,box)
  return width + 30,height
end

local function draw(data,item,args)
  local args,flags = args or {},{}
  for _,v in pairs(args) do flags[v] = true end

  if not item._internal.align._setup then
    item._internal.align._setup = true
    item._internal.align.first._fit = item._internal.align.first.fit
    item._internal.align.first._draw = item._internal.align.first.draw
    item._internal.align.first.fit = prefix_fit
    item._internal.align.first.draw = prefix_draw
--     item._internal.align.first:emit_signal("widget::updated")
  end

  if flags[base.item_flags.SELECTED] or (item._tmp_menu) then
    item.widget:set_bg(args.color or data.bg_focus)
  else
    item.widget:set_bg(args.color or nil)
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
