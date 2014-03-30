local setmetatable = setmetatable
local base      = require( "radical.base"               )
local beautiful = require("beautiful"                   )
local color     = require("gears.color"                 )
local cairo     = require("lgi"                         ).cairo
local wibox     = require("wibox"                       )
local arrow_alt = require("radical.item.style.arrow_alt")

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

  -- This item style require negative padding, this is a little dangerous to
  -- do as it can corrupt area outside of the widget
  local col = self._item.bg_prefix or beautiful.icon_grad or beautiful.fg_normal
  cr:set_source(color(col))
  cr:move_to(-height/2-2,0)
  cr:line_to(width-height+2,0)
  cr:rel_line_to(height*.6,height/2)
  cr:line_to(width-height+2,height)
  cr:line_to(-height*.6,height)
  cr:line_to(0,height/2)
  cr:close_path()
  cr:reset_clip()
  cr:fill()
  cr:restore()
  self._draw(self, w, cr, width, height)
end

local function prefix_fit(box,w,h)
  local width,height = box._fit(box,w,h)
  return width + h/2 + h/6,height
end

local function suffix_fit(box,w,h)
  local width,height = box._fit(box,w,h)
  return width + h/2 + h/6,height
end

local function widget_draw(self, w, cr, width, height)
  self:_drawprefix(w, cr, width, height)
  local overlay = self._item and self._item.overlay
  if overlay then
    overlay(self._item._menu,self._item,cr,width,height)
  end
end

local function draw(item,args)
  local args = args or {}

  if not item.widget._overlay_init then
    item.widget._drawprefix = item.widget.draw
    item.widget.draw = widget_draw
    item.widget._overlay_init = true
  end

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
    item._internal.align.third.fit = suffix_fit
  end

  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = base.colors_by_id[current_state]

  if current_state == base.item_flags.SELECTED or (item._tmp_menu) then
    item.widget:set_bg(args.color or item.bg_focus)
    item.widget:set_fg(item["fg_focus"])
  elseif state_name then
    item.widget:set_bg(args.color or item["bg_"..state_name])
    item.widget:set_fg(              item["fg_"..state_name])
  else
    item.widget:set_bg(args.color or nil)
    item.widget:set_fg(item["fg"])
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
