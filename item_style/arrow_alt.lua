local setmetatable = setmetatable
local print = print

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 30,
    LEFT   = 30
  }
}

local function draw(data,item,is_focussed,is_pressed,col)
  if is_focussed or (item._tmp_menu) then
    item.widget:set_bg(col or data.bg_focus)
  else
    item.widget:set_bg(col or nil)
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
