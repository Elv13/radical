local radical = require("radical")
local capi = { screen = screen, client=client}
local awful     = require( "awful"      )
local beautiful =  require("beautiful")
local suits = require("awful.layout.suit")
local wibox = require("wibox")
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

local function createTagList(aScreen,args)
  if not tag_list then
    tag_list = require("radical.impl.taglist")
  end
  local tagList = args.menu or radical.context {}
  local ret = {}
  for _, v in ipairs(awful.tag.gettags(aScreen)) do
    args.text,args.icon = v.name,awful.tag.geticon(v)
    local i = tagList:add_item(args)
    i._tag = v
    ret[v] = i
    i:connect_signal("mouse::enter",function()
      tag_list.highlight(v)
    end)
  end
  tagList:connect_signal("visible::changed",function()
    if not tagList.visible then
      tag_list.highlight(nil)
    end
  end)
  return tagList,ret
end

function module.listTags(args, menu)
  local args = args or {}
  if capi.screen.count() == 1 or args.screen then
    return createTagList(args.screen or 1,args or {})
  else
    local screenSelect = radical.context {}
    for i=1, capi.screen.count() do
      screenSelect:add_item({text="Screen "..i , sub_menu = createTagList(i,args or {})})
    end
    return screenSelect
  end
end

function module.layouts(menu,layouts)
  local cur = awful.layout.get(awful.tag.getscreen(awful.tag.selected(capi.client.focus and capi.client.focus.screen)))
  local screenSelect = menu or radical.context {}
  local layouts = layouts or awful.layout.layouts or fallback_layouts
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

--Update the 

-- Widget to replace the default awesome layoutbox
function module.layout_item(menu,args)
  local args = args or {}
  local ib = wibox.widget.imagebox()
  local screen = args.screen or 1
  local sub_menu = nil
  
  local function toggle()
    if not sub_menu then
      sub_menu = radical.context{
        filter      = false                             ,
        item_style  = radical.item.style.rounded        ,
        item_height = 30                                ,
        column      = 3                                 ,
        layout      = radical.layout.grid               ,
        arrow_type  = radical.base.arrow_type.CENTERED  ,
      }
      module.layouts(sub_menu)
    end
    sub_menu.visible = not sub_menu.visible
  end
  
  --TODO button 4 and 5
  local item = menu:add_item{text=args.text,button1=toggle,tooltip=args.tooltip}
  
  local function update()
    local layout = awful.layout.getname(awful.layout.get(screen))
    local ic = beautiful["layout_small_" ..layout] or beautiful["layout_" ..layout]
    item.icon = ic
  end
  update()

  awful.tag.attached_connect_signal(screen, "property::selected", update)
  awful.tag.attached_connect_signal(screen, "property::layout"  , update)
end

return setmetatable(module, { __call = function(_, ...) return module.listTags(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;