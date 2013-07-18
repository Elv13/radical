local setmetatable = setmetatable
local print        = print
local ipairs       = ipairs
local math         = math
local wibox        = require( "wibox" )

local module = {}

local function left(data)
  data.next_item.selected = true
end

local function right(data)
  data.previous_item.selected = true
end

local function up(data)
  local idx,rc,col = data.current_index,data.rowcount,data.column
  idx = idx-col
  if idx <= 0 then
    idx = rc + idx + 1
  end
  data.items[idx][1].selected = true
end

local function down(data)
  local idx,rc,col = data.current_index,data.rowcount,data.column
  idx = idx+col
  if idx > rc then
    idx = idx - rc - 1
  end
  data.items[idx][1].selected = true
end

function module:setup_key_hooks(data)
  data:add_key_hook({}, "Up"      , "press", up    )
  data:add_key_hook({}, "&"       , "press", up    )
  data:add_key_hook({}, "Down"    , "press", down  )
  data:add_key_hook({}, "KP_Enter", "press", down  )
  data:add_key_hook({}, "Left"    , "press", left  )
  data:add_key_hook({}, "\""      , "press", left  )
  data:add_key_hook({}, "Right"   , "press", right )
  data:add_key_hook({}, "#"       , "press", right )
end

--Get preferred item geometry
local function item_fit(data,item,...)
  return data.item_height, data.item_height
end

local function new(data)
  local counter = 0
  local mode = data.column ~= nil
  local rows = {}
  local l = wibox.layout.fixed[mode and "horizontal" or "vertical"]()
  local constraint = mode and data.column or data.row or 2
  for i=1,constraint do
    local l2 = wibox.layout.fixed[mode and "vertical" or "horizontal"]()
    l:add(l2)
    rows[#rows+1] = l2
  end
  l.fit = function(a1,a2,a3)
    local r1,r2 = data.item_height*math.ceil(data.rowcount/constraint),data.item_height*constraint
    return (mode and r2 or r1),(mode and r1 or r2)
  end
  l.add = function(l,item)
    for k,v in ipairs(rows) do
      v:reset()
    end
    local rc = data.rowcount+1
    for i=1,rc do
      rows[((i-1)%constraint)+1]:add((rc == i and item.widget or data.items[i][1].widget))
    end
    return true
  end
  --TODO only load the layouts when draw() is called
  l.item_fit = item_fit
  return l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
