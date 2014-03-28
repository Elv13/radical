local radical = require("radical")
local capi = { screen = screen, client=client}
local awful     = require( "awful"      )
local beautiful =  require("beautiful")
local suits = require("awful.layout.suit")
local tag_list = nil

local module = {}

local fallback_layouts = {
  suits.floating,
  suits.tile,
  suits.tile.left,
  suits.tile.bottom,
  suits.tile.top,
  suits.fair,
  suits.fair.horizontal,
  suits.spiral,
  suits.spiral.dwindle,
  suits.max,
  suits.max.fullscreen,
  suits.magnifier
}

local function createTagList(aScreen)
  if not tag_list then
    tag_list = require("radical.impl.taglist")
  end
  local tagList = radical.context({autodiscard = true})
  for _, v in ipairs(awful.tag.gettags(aScreen)) do
    local i = tagList:add_item({text = v.name,icon=awful.tag.geticon(v)})
    i:connect_signal("mouse::enter",function()
      tag_list.highlight(v)
    end)
  end
  tagList:connect_signal("visible::changed",function()
    if not tagList.visible then
      tag_list.highlight(nil)
    end
  end)
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

function module.layouts(menu,layouts)
  local cur = awful.layout.get(awful.tag.getscreen(awful.tag.selected(capi.client.focus and capi.client.focus.screen)))
  local screenSelect = menu or radical.context(({autodiscard = true}))
  local layouts = layouts or fallback_layouts
  for i, layout_real in ipairs(layouts) do
    local layout2 = awful.layout.getname(layout_real)
    if layout2 and beautiful["layout_" ..layout2] then
      screenSelect:add_item({icon=beautiful["layout_" ..layout2],button1 = function(_,mod)
        if mod then
          screenSelect[mod[1] == "Shift" and "previous_item" or "next_item"].selected = true
        end
        awful.layout.set(layouts[screenSelect.current_index] or layouts[1],awful.tag.selected(capi.client.focus and capi.client.focus.screen))
      end, selected = (layout_real == cur), item_layout = radical.item.layout.icon})
    end
  end
  return screenSelect
end

return setmetatable(module, { __call = function(_, ...) return module.listTags(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;