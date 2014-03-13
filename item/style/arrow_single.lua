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
  local overlay = self._item and self._item.overlay
  if overlay then
    overlay(self._item._menu,self._item,cr,width,height)
  end
  cr:restore()
end


local function draw(item,args)
  local args = args or {}

  item.widget.draw = suffix_draw

  local state = item.state or {}
  local current_state = state._current_key or nil
  local state_name = base.colors_by_id[current_state]
  if current_state == base.item_flags.SELECTED or (item._tmp_menu) then
    item.widget:set_bg(args.color or item.bg_focus)
    item.widget:set_fg(item.fg_focus)
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
