local setmetatable = setmetatable
local print = print
local pairs=pairs
local base      = require( "radical.base"     )

local module = {
  margins = {
    TOP    = 2,
    BOTTOM = 2,
    RIGHT  = 2,
    LEFT   = 4
  }
}

local function draw(data,item,args)
  local args,flags = args or {},{}
  for _,v in pairs(args) do flags[v] = true end

  if flags[base.item_flags.SELECTED] or (item._tmp_menu) then
    item.widget:set_bg(args.color or data.bg_focus)
  else
    item.widget:set_bg(args.color or nil)
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
