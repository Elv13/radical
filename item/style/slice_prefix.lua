local setmetatable = setmetatable
local beautiful = require("beautiful"                   )
local color     = require("gears.color"                 )
local theme     = require( "radical.theme" )

local module = {
  margins = {
    TOP    = 0,
    BOTTOM = 0,
    RIGHT  = 0,
    LEFT   = 0
  },
  need_full_repaint = true
}

local function prefix_before_draw_children(self, context, cr, width, height)
  cr:save()

  -- This item style require negative padding, this is a little dangerous to
  -- do as it can corrupt area outside of the widget
  local col = self._item.bg_prefix or beautiful.icon_grad or beautiful.fg_normal
  cr:set_source(color(col))
  cr:move_to(0,0)
  cr:line_to(width,0)
  cr:line_to(width-height/2-height/4,height)
  cr:line_to(-height/2-height/4,height)
  cr:close_path()
  cr:reset_clip()
  cr:fill()
  cr:restore()

end

local function prefix_fit(box,context,w,h)
  local width,height = box._fit(box,context,w,h)
  return width + h/2,height
end

local function suffix_fit(box,context,w,h)
  local width,height = box._fit(box,context,w,h)
  return width + h/2 + h/6,height
end

local function draw(item)

  if not item.widget._overlay_init then
    item.widget._drawprefix = item.widget.draw
    item.widget._overlay_init = true
  end

  if not item._internal.align._setup then
    item._internal.align._setup = true

    -- Replace prefix function
    item._internal.align.first._item = item
    item._internal.align.first._fit = item._internal.align.first.fit
    item._internal.align.first.fit = prefix_fit
    item._internal.align.first.before_draw_children = prefix_before_draw_children

    -- Replace suffix function
    item._internal.align.third._item = item
    item._internal.align.third._fit = item._internal.align.third.fit
    item._internal.align.third.fit = suffix_fit
  end

  theme.update_colors(item)
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
