local radical = require("radical")
local capi = { screen = screen, client=client}
local awful     = require( "awful"      )
local beautiful =  require("beautiful")
local tag_list = nil

local module = {}

local function createTagList(aScreen,args)
  if not tag_list then
    tag_list = require("radical.impl.taglist")
  end
  local tagList = args.menu or radical.context {}
  local ret = {}
  for _, v in ipairs(capi.screen[aScreen].tags) do
    args.text,args.icon = v.name,v.icon
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
  args = args or {}
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
  local cur = awful.layout.get(capi.client.focus and capi.client.focus.screen)
  local screenSelect = menu or radical.context {}

  layouts = layouts or awful.layout.layouts

  for i, layout_real in ipairs(layouts) do
    local layout2 = awful.layout.getname(layout_real)
    local is_current = cur and ((layout_real == cur) or (layout_real.name == cur.name))
    if layout2 and beautiful["layout_" ..layout2] then
      screenSelect:add_item({icon=beautiful["layout_" ..layout2],button1 = function(_,mod)
        if mod then
          screenSelect[mod[1] == "Shift" and "previous_item" or "next_item"].selected = true
        end
        awful.layout.set(layouts[screenSelect.current_index ] or layouts[1], (capi.client.focus and capi.client.focus.screen.selected_tag))
      end, selected = is_current, item_layout = radical.item.layout.icon})
    end
  end
  return screenSelect
end

--Update the 

-- Widget to replace the default awesome layoutbox
function module.layout_item(menu,args)
  args = args or {}
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
    local ic = beautiful["layout_" ..layout]
    item.icon = ic
  end
  update()

  awful.tag.attached_connect_signal(screen, "property::selected", update)
  awful.tag.attached_connect_signal(screen, "property::layout"  , update)

  return item
end

return setmetatable(module, { __call = function(_, ...) return module.listTags(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
