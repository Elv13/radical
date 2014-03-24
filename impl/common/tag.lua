local radical = require("radical")
local capi = { screen = screen, }
local awful     = require( "awful"      )
local module = {}

local function createTagList(aScreen)
  local tagList = radical.context({autodiscard = true})
  for _, v in ipairs(awful.tag.gettags(aScreen)) do
    tagList:add_item({text = v.name,icon=awful.tag.geticon(v)})
  end
  return tagList
end

function module.listTags()
  if capi.screen.count() == 1 then
    return createTagList(1)
  else
    local screenSelect = radical.context(({autodiscard = true}))
    for i=1, capi.screen.count() do
      screenSelect:add_item({text="Screen "..i , sub_menu = createTagList(i)})
    end
    return screenSelect
  end
end

return setmetatable(module, { __call = function(_, ...) return module.listTags(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;