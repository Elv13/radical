local radical   = require( "radical"                 )
local com_tag   = require( "radical.impl.common.tag" )
local beautiful = require( "beautiful"               )
local tag       = require( "awful.tag"               )
local capi = { client = client, mouse = mouse, screen = screen}

local module = {}

local function is_checked(m,i)
  return true
end

local function select_tag(i,m)
  local t = i._tag
  tag.viewonly(t)
end

local function toggle_tag(i,m)
  local t = i._tag
  t.selected = not t.selected
  i.checked = t.selected
end

local function new(args)
  args = args or {}

  local auto_release = args.auto_release
  local currentMenu = radical.box({filter = true, show_filter=not auto_release, autodiscard = true,
    disable_markup=true,fkeys_prefix=not auto_release,width=(((capi.screen[capi.client.focus and capi.client.focus.screen or capi.mouse.screen]).geometry.width)/2),
    icon_transformation = beautiful.alttab_icon_transformation,filter_underlay="Use [Shift] and [Control] to toggle clients",filter_underlay_color=beautiful.menu_bg_normal,
    filter_placeholder="<span fgcolor='".. (beautiful.menu_fg_disabled or beautiful.fg_disabled or "#777777") .."'>Type to filter</span>"})

  com_tag.listTags({menu=currentMenu,checkable=true,checked=is_checked,button1=select_tag})

  currentMenu:add_key_hook({}, "Shift_L", "press", function()
    local item = currentMenu._current_item
    toggle_tag(item,currentMenu)
    return true
  end)

  currentMenu:add_key_hook({}, "Control_L", "press", function()
    local item = currentMenu._current_item
    item.checked = not item.checked
    return true
  end)

  currentMenu.visible = true
  return currentMenu
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
