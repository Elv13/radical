local setmetatable,type = setmetatable, type
local ipairs, pairs     = ipairs, pairs
local button    = require( "awful.button"         )
local beautiful = require( "beautiful"            )
local tag       = require( "awful.tag"            )
local client2   = require( "awful.client"         )
local radical   = require( "radical"              )
local util      = require( "awful.util"           )
local wibox     = require( "wibox"                )
local tag_list  = require( "radical.impl.taglist" )
local capi = { client = client, mouse = mouse, screen = screen}

local module,pause_monitoring = {},false

-- Keep its own history instead of using awful.client.focus.history
local focusIdx,focusTable = 1,setmetatable({}, { __mode = 'v' })
local focusTag = setmetatable({}, { __mode = 'v' })
local function push_focus(c)
  if c and not pause_monitoring then
    focusTable[c] = focusIdx
    focusIdx = focusIdx + 1
    focusTag[c] = tag.selected(c.screen)
  end
end
capi.client.connect_signal("focus", push_focus)

-- Remove client when closed
client.connect_signal("unmanage", function (c)
  focusTable[c] = nil
end)

local function compare(a,b)
  return a[1] > b[1]
end

local function get_history(screen)
  local result = {}
  for k,v in pairs(focusTable) do
    result[#result+1] = {v,k}
  end
  local orphanCount = -100
  for k,v in ipairs(capi.client.get(screen or 1)) do
    if not focusTable[v] then
      result[#result+1] = setmetatable({orphanCount,v}, { __mode = 'v' })
      orphanCount = orphanCount -1
    end
  end
  table.sort(result,compare)
  return result
end

-- Simulate a titlebar
local function button_group(args)
  local widget   = wibox.widget.imagebox()
  widget:set_image( module.titlebar_path.. args.field .."_normal_"..(args.checked() and "active" or "inactive")..".png" )
  widget:buttons( util.table.join(button({ }, 1 , args.onclick)))
  return widget
end

local function select_next(menu)
  local item = menu.next_item
  if not item then return end
  item.selected = true
  item.button1(nil,nil,nil,nil,true)
  return true
end

local function is_in_tag(t,c)
  for k,v in ipairs(c:tags()) do if t == v then return true end end
  return false
end

local function reload_underlay(client,item)
  local underlays = {}
  for k,v in ipairs(client:tags()) do
    underlays[#underlays+1] = v.name
  end
  if item then
    item.underlay = underlays
  end
  return underlays
end

local function reload_highlight(i)
  if i.selected then
    local hl = {}
    for k,v in ipairs(i.client:tags()) do
      hl[#hl+1] = v
    end
    tag_list.highlight(hl)

    i._internal.border_color_back = i.client.border_color
    i.client.border_color = beautiful.bg_urgent
  elseif i._internal.border_color_back then
    i.client.border_color = i._internal.border_color_back
  end
end

local function new(args)
  local histo = get_history(--[[screen]])
  if #histo == 0 then
    return
  end

  local t,auto_release = tag.selected(capi.client.focus and capi.client.focus.screen or capi.mouse.screen),args.auto_release
  local currentMenu = radical.box({filter = true, show_filter=not auto_release, autodiscard = true,
    disable_markup=true,fkeys_prefix=not auto_release,width=(((capi.screen[capi.client.focus and capi.client.focus.screen or capi.mouse.screen]).geometry.width)/2),
    icon_transformation = beautiful.alttab_icon_transformation,filter_underlay="Use [Shift] and [Control] to toggle clients",filter_underlay_color=beautiful.menu_bg_normal,
    filter_placeholder="<span fgcolor='".. (beautiful.menu_fg_disabled or beautiful.fg_disabled or "#777777") .."'>Type to filter</span>"})

  if not auto_release then
    local pref_bg = wibox.widget.background()
    local pref_l = wibox.layout.align.horizontal()
    pref_bg.fit = function(s,w,h)
      local w2,h2 = wibox.widget.background.fit(s,w,h)
      return w2,currentMenu.item_height
    end
    pref_bg:set_bg(currentMenu.bg_alternate)
    local tb2= wibox.widget.textbox()
    tb2:set_text("foo!!!!")
    pref_l:set_first(tb2)
    pref_bg:set_widget(pref_l)
    local pref_menu,pref_menu_l = radical.bar{item_style=radical.item.style.basic}
    pref_menu:add_widget(radical.widgets.separator(pref_menu,radical.widgets.separator.VERTICAL))
    pref_menu:add_item{text="Exclusive"}
    pref_menu:add_widget(radical.widgets.separator(pref_menu,radical.widgets.separator.VERTICAL))
    pref_menu:add_item{text="12 clients"}
    pref_menu:add_widget(radical.widgets.separator(pref_menu,radical.widgets.separator.VERTICAL))
    pref_menu:add_item{text="All Screens"}
    pref_menu:add_widget(radical.widgets.separator(pref_menu,radical.widgets.separator.VERTICAL))
    pref_l:set_third(pref_menu_l)

    currentMenu:add_prefix_widget(pref_bg)
  end

  currentMenu:add_key_hook({}, "Tab", "press", select_next)
  currentMenu:add_key_hook({}, "Shift_L", "press", function()
    currentMenu._current_item.checked = not currentMenu._current_item.checked
    client2.toggletag (t, currentMenu._current_item.client)
    reload_underlay(currentMenu._current_item.client,currentMenu._current_item)
    if not auto_release then
      reload_highlight(currentMenu._current_item)
    end
    return true
  end)
  currentMenu:add_key_hook({}, "Control_L", "press", function()
    currentMenu._current_item.checked = not currentMenu._current_item.checked
    client2.movetotag(t, currentMenu._current_item.client)
    reload_underlay(currentMenu._current_item.client,currentMenu._current_item)
    if not auto_release then
      reload_highlight(currentMenu._current_item)
    end
    return true
  end)


  for k,v2 in ipairs(histo) do
    local l,v = wibox.layout.fixed.horizontal(),v2[2]
    if not auto_release and module.titlebar_path then
      l:add( button_group({client = v, field = "floating" , focus = false, checked = function() return v.floating  end, onclick = function() v.floating  = not v.floating  end }))
      l:add( button_group({client = v, field = "maximized", focus = false, checked = function() return v.maximized end, onclick = function() v.maximized = not v.maximized end }))
      l:add( button_group({client = v, field = "sticky"   , focus = false, checked = function() return v.sticky    end, onclick = function() v.sticky    = not v.sticky    end }))
      l:add( button_group({client = v, field = "ontop"    , focus = false, checked = function() return v.ontop     end, onclick = function() v.ontop     = not v.ontop     end }))
      l:add( button_group({client = v, field = "close"    , focus = false, checked = function() return false       end, onclick = function() v:kill()                      end }))
      l.fit = function (s,w,h) return 5*h,h end
    end

    local underlays = reload_underlay(v)

    local i = currentMenu:add_item({
      text          = v.name,
      icon          = v.icon or module.default_icon,
      suffix_widget = not auto_release and l or nil,
      selected      = capi.client.focus and capi.client.focus == v,
      underlay      = underlays,
      checkable     = not auto_release,
      checked       = not auto_release and is_in_tag(t,v) or nil,
      button1       = function(a,b,c,d,no_hide)
        local t = focusTag[v] or v:tags()[1]
        if t and t.selected == false and not util.table.hasitem(v:tags(),tag.selected(v.screen)) then
          tag.viewonly(t)
        end
        capi.client.focus = v
        v:raise()
        if not no_hide then
          currentMenu.visible = false
        end
      end,
    })
    i.client = v

    if not auto_release then
      i:connect_signal("selected::changed",reload_highlight)
    end
  end

  if auto_release then
    currentMenu:add_key_hook({}, "Alt_L", "release", function(_)
      currentMenu.visible = false
      return false
    end)
    select_next(currentMenu)
  end

  pause_monitoring,currentMenu.visible = true, true
  currentMenu:connect_signal("visible::changed",function(m)
    if not m.visible then
      pause_monitoring = false
      push_focus(capi.client.focus)
      if not auto_release then
        tag_list.highlight()
      end
      if currentMenu._current_item and currentMenu._current_item._internal.border_color_back then
        currentMenu._current_item.client.border_color = currentMenu._current_item._internal.border_color_back
      end
    end
  end)
  return currentMenu
end

function module.altTab(args)
  new({leap = 1,auto_release = (args or {}).auto_release})
end

function module.altTabBack(args)
  new({leap = -1,auto_release = (args or {}).auto_release})
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
