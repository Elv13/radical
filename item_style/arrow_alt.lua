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

local hcode = {"#7777ff","#ff7777","#77ff77"}

local end_cache = {}
module.get_end_arrow = function(args)
    local args = args or {}
    local default_height = beautiful.default_height or 16
    local bgt = type(args.bg_color)
    local width,height = (args.width or default_height/2+1),args.height or default_height
    local img = cairo.ImageSurface(cairo.Format.ARGB32, width+(args.padding or 0), height)
    local cr = cairo.Context(img)
    cr:set_source(color(args.bg_color or beautiful.bg_normal))
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
  wibox.widget.background.draw(self, w, cr, width, height)
  cr:save()
  cr:set_source_surface(module.get_end_arrow({width=height/2+2,height=height,bg_color=self.next_color or  "#ff0000"}),width-height/2-2,0)
  cr:paint()
  cr:restore()
  self.widget:draw(w, cr, width, height)
end

local function get_prev(data,item)
  for k,v in ipairs(data.items) do
    if v[1] == item then
      while k > 0 do
        k = k - 1
        if k > 0 and (not data.items[k][1].hidden) and data.items[k][1]._internal.f_key == item._internal.f_key - 1 then
          return data.items[k][1]
        end
      end
      return nil
    end
  end
end

local function draw(data,item,args)
  local args,flags = args or {},{}
  for _,v in pairs(args) do flags[v] = true end
  if item.widget.draw ~= draw_real then
    item.widget.draw = draw_real
    item.widget:emit_signal("widget::updated")
  end

  local color_idx = math.mod(item.f_key,#hcode) + 1
  local previous_idx = color_idx == 1 and #hcode or color_idx - 1
  local next_idx = color_idx + 1 > #hcode and 1 or (color_idx + 1)
  local prev_color = item.widget.next_color
  item.widget.next_color = hcode[next_idx]

  local prev_item = get_prev(data,item)
  if flags[base.item_flags.SELECTED] or (item._tmp_menu) then
    if prev_item and prev_item.widget.next_color ~= (args.color or data.bg_focus) then
      prev_item.widget.next_color = args.color or data.bg_focus
      prev_item.widget:emit_signal("widget::updated")
    end
    item.widget:set_bg(args.color or data.bg_focus)
  else
    if prev_item and prev_item.widget.next_color ~= hcode[color_idx] then
      prev_item.widget.next_color = hcode[color_idx]
      prev_item.widget:emit_signal("widget::updated")
    end
    item.widget:set_bg(args.color or hcode[color_idx])
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
