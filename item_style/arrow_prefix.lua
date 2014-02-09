local setmetatable = setmetatable
local base      = require( "radical.base"               )
local beautiful = require("beautiful"                   )
local color     = require("gears.color"                 )
local cairo     = require("lgi"                         ).cairo
local wibox     = require("wibox"                       )
local arrow_alt = require("radical.item_style.arrow_alt")

local module = {
  margins = {
    TOP    = 0,
    BOTTOM = 0,
    RIGHT  = 0,
    LEFT   = 0
  }
}

local function prefix_draw(self, w, cr, width, height)
  cr:save()
  local col = self._item.bg_prefix or beautiful.icon_grad or beautiful.fg_normal
  cr:set_source(color(col))
  cr:rectangle(0,0,width-height/2-2-height/6,height)
  cr:fill()
  cr:set_source_surface(arrow_alt.get_beg_arrow({width=height/2+2,height=height,bg_color=col}),width-height/2-2 - height/6,0)
  cr:paint()
  cr:restore()
  self._draw(self, w, cr, width, height)
end

local function prefix_fit(box,w,h)
  local width,height = box._fit(box,w,h)
  return width + h/2 + h/6,height
end

local function suffix_draw(self, w, cr, width, height)
  cr:save()
  cr:set_source_surface(arrow_alt.get_end_arrow({width=height/2+2,height=height,bg_color=self._item.bg_prefix or beautiful.icon_grad or beautiful.fg_normal}),width-height/2-2,0)
  cr:paint()
  cr:restore()
  self._draw(self, w, cr, width, height)
end

local function suffix_fit(box,w,h)
  local width,height = box._fit(box,w,h)
  return width + h/2 + h/6,height
end

local function draw(data,item,args)
  local args,flags = args or {},{}
  for _,v in pairs(args) do flags[v] = true end

  if not item._internal.align._setup then
    item._internal.align._setup = true

    -- Replace prefix function
    item._internal.align.first._item = item
    item._internal.align.first._fit = item._internal.align.first.fit
    item._internal.align.first._draw = item._internal.align.first.draw
    item._internal.align.first.fit = prefix_fit
    item._internal.align.first.draw = prefix_draw

    -- Replace suffix function
    item._internal.align.third._item = item
    item._internal.align.third._fit = item._internal.align.third.fit
    item._internal.align.third._draw = item._internal.align.third.draw
    item._internal.align.third.fit = suffix_fit
    item._internal.align.third.draw = suffix_draw
  end

  if flags[base.item_flags.SELECTED] or (item._tmp_menu) then
    item.widget:set_bg(args.color or data.bg_focus)
  elseif flags[base.item_flags.HOVERED] then
    item.widget:set_bg(args.color or data.bg_hover)
  else
    item.widget:set_bg(args.color or nil)
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
