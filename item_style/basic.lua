local setmetatable = setmetatable
local print = print

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 2,
    LEFT   = 4
  }
}

local function draw(data,item,is_focussed,is_pressed)
  if is_focussed or (item._tmp_menu) then
    item.widget:set_bg(data.bg_focus)
  else
    item.widget:set_bg(nil)
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
