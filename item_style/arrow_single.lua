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
    RIGHT  = 15,
    LEFT   = 15
  }
}


local function suffix_draw(self, w, cr, width, height)
  cr:save()
  cr:move_to(height/2,0)
  cr:line_to(width-height/2,0)
  cr:line_to(width,height/2)
  cr:line_to(width-height/2,height)
  cr:line_to(height/2,height)
  cr:line_to(0,height/2)
  cr:line_to(height/2,0)
  cr:close_path()
  cr:clip()
  wibox.widget.background.draw(self, w, cr, width, height)
  cr:restore()
end


local function draw(data,item,args)
  local args,flags = args or {},{}
  for _,v in pairs(args) do flags[v] = true end

  item.widget.draw = suffix_draw

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
