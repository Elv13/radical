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

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 20,
    LEFT   = 3
  }
}

local hcode = {"#7777ff","#ff7777","#77ff77","#77ffff","#ffff77"}

local end_cache = {}
module.get_end_arrow = function(args)
    local args = args or {}
    local default_height = beautiful.default_height or 16
    local bgt = type(args.bg_color)
    local width,height = (args.width or default_height/2+1),args.height or default_height
    local img = cairo.ImageSurface(cairo.Format.ARGB32, width+(args.padding or 0), height)
    local cr = cairo.Context(img)
    cr:set_source(color(args.bg_color or beautiful.bg_normal))
    cr:set_antialias(cairo.ANTIALIAS_NONE)
    cr:new_path()
    if (args.direction == "left") then
        cr:move_to(0,width+(args.padding or 0))
        cr:line_to(0,height/2)
        cr:line_to(width+(args.padding or 0),height)
        cr:line_to(0,height)
        cr:line_to(0,0)
        cr:line_to(width+(args.padding or 0),0)
    else
        cr:line_to(width+(args.padding or 0),0)
        cr:line_to(width+(args.padding or 0),height)
        cr:line_to(0,height)
        cr:line_to(width-1,height/2)
        cr:line_to(0,0)
    end
    cr:close_path()
    cr:fill()
    return img
end

local beg_cache = {}
module.get_beg_arrow = function(args)
    local args = args or {}
    local default_height = beautiful.default_height or 16
    local bgt = type(args.bg_color)
    local width,height = (args.width or default_height/2+1)+(args.padding or 0),args.height or default_height
    local img = cairo.ImageSurface(cairo.Format.ARGB32, width, height)
    local cr = cairo.Context(img)
    cr:set_source(color(args.bg_color or beautiful.fg_normal))
    cr:set_antialias(cairo.ANTIALIAS_NONE)
    cr:new_path()
    if (args.direction == "left") then
        cr:move_to(0,width)
        cr:line_to(0,height/2)
        cr:line_to(width,height)
        cr:line_to(width,0)
    else
        cr:line_to(width,height/2)
        cr:line_to(0,height)
        cr:line_to(0,0)
    end
    cr:close_path()
    cr:fill()
    return img
end

local function draw_real(self, w, cr, width, height)
--   wibox.widget.background.draw(self, w, cr, width, height)
  cr:save()

  -- This item style require negative padding, this is a little dangerous to
  -- do as it can corrupt area outside of the widget
  local col = self._item.bg_prefix or beautiful.icon_grad or beautiful.fg_normal
  cr:set_source(color(self.background))
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

  self.widget:draw(w, cr, width, height)
  local overlay = self._item and self._item.overlay
  if overlay then
    overlay(self._item._menu,self._item,cr,width,height)
  end
end

local function draw(item,args)
  local args = args or {}
  if item.widget.draw ~= draw_real then
    item.widget._draw = item.widget.draw
    item.widget.draw = draw_real
    item.widget:emit_signal("widget::updated")
  end

  local color_idx = math.mod(item.f_key,#hcode) + 1
  local next_idx = color_idx + 1 > #hcode and 1 or (color_idx + 1)

  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = base.colors_by_id[current_state]

  if current_state == base.item_flags.SELECTED or (item._tmp_menu) then
    item.widget:set_fg(item["fg_focus"])
    item.widget:set_bg(args.color)
  elseif state_name then --TODO untested, most likely broken
    item.widget:set_bg(args.color or item["bg_"..state_name])
    item.widget:set_fg(              item["fg_"..state_name])
  else
    item.widget:set_bg(args.color or hcode[color_idx])
    item.widget:set_fg(item["fg_normal"])
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
