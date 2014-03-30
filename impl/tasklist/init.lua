---------------------------------------------------------------------------
-- @author Emmanuel Lepage Vallee <elv1313@gmail.com>
-- @copyright 2014 Emmanuel Lepage Vallee
-- @release devel
-- @note Based on the original tasklist.lua
-- @license GPLv2+ because of copy paste from the old tasklist.lua
---------------------------------------------------------------------------

local capi = {client = client,tag=tag}
local rawset = rawset
local radical   = require( "radical"      )
local tag       = require( "awful.tag"    )
local beautiful = require( "beautiful"    )
local client = require( "awful.client" )
local wibox     = require( "wibox"        )
local client_menu =  require("radical.impl.tasklist.client_menu")
local theme     = require( "radical.theme")

local sticky,urgent,instances,module = {extensions=require("radical.impl.tasklist.extensions")},{},{},{}
local _cache = setmetatable({}, { __mode = 'k' })
local MINIMIZED = 101
theme.register_color(MINIMIZED , "minimized" , "tasklist_minimized" , true )

-- Default button implementation
module.buttons = {
  [1] = function (c)
    if c == capi.client.focus then
      c.minimized = true
    else
      -- Without this, the following
      -- :isvisible() makes no sense
      c.minimized = false
      if not c:isvisible() then
          tag.viewonly(c:tags()[1])
      end
      -- This will also un-minimize
      -- the client, if needed
      capi.client.focus = c
      c:raise()
    end
  end,
  [3] = function(c)
    client_menu.client = c
    local menu = client_menu()
    menu.visible = not menu.visible
  end,
  [4] = function ()
    client.focus.byidx(1)
    if client.focus then client.focus:raise() end
  end,
  [5] = function ()
    client.focus.byidx(-1)
    if capi.client.focus then client.focus:raise() end
  end
}

local function sticky_callback(c)
  local val = c.sticky
  sticky[c] = val and true or nil
  local menu = instances[c.screen].menu
  local is_in_tag = false
  for _,t in ipairs(tag.selectedlist(k)) do
    for k2,v2 in ipairs(c:tags()) do
      if v2 == t then
        is_in_tag = true
        break
      end
    end
    if is_in_tag then break end
  end
  if not is_in_tag then
    if val then
      menu:append(_cache[c])
    else
      menu:remove(_cache[c])
    end
  end
end

local function urgent_callback(c)
  local val = c.urgent
  urgent[c] = val and true or nil
  local item = _cache[c]
  if item then
    item.state[radical.base.item_flags.URGENT] = val or nil
  end
end

local function minimize_callback(c)
  local item = _cache[c]
  if item then
    local val = c.minimized
    item.state[MINIMIZED] = val or nil
  end
end

local function unmanage_callback(c)
  sticky[c] = nil
  urgent[c] = nil
  for k,v in ipairs(instances) do
    v.menu:remove(_cache[c])
  end
  _cache[c] = nil
end

-- Reload <float> <ontop> and <sticky> labels
local function reload_underlay(c)
  local udl,item = {},_cache[c]
  if item then
    if c.ontop then
      udl[#udl+1] = "ontop"
    end
    if client.floating.get(c) then
      udl[#udl+1] = "float"
    end
    if c.sticky then
      udl[#udl+1] = "sticky"
    end
    item.underlay = udl
    item.widget:emit_signal("widget::updated")
  end
end

-- Reload title and icon
local function reload_content(c,b,a)
  local item = _cache[c]
  if item then
    item.text = c.name or "N/A"
    item.icon = c.icon or beautiful.tasklist_default_icon
  end
end


local function create_client_item(c,screen)
  local item = _cache[c]
  local menu = instances[screen].menu
  -- If it already exist, don't waste time creating a copy
  if item then
    menu:append(item)
    return item
  end

  -- Too bad, let's create a new one
  local suf_w = wibox.layout.fixed.horizontal()
  item = menu:add_item{text=c.name,icon=c.icon,suffix_widget=suf_w}
  item.add_suffix = function(w,w2)
    suf_w:add(w2)
  end
  item.client = c
  _cache[c] = item
  return item
end

-- Add client to the tasklist
local function add_client(c,screen)
  if not (c.skip_taskbar or c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop") and c.screen == screen then
    local ret = create_client_item(c,screen)
    reload_underlay(c)
    if capi.client.focus == c then
      ret.selected = true
    end
  end
end

-- Clear the menu and repopulate it
local function load_clients(t)
  local screen = tag.getscreen(t)
  if not t or not screen or not instances[screen] then return end
  local menu = instances[screen].menu
  if t.selected then
    menu:clear()
    for k, c in ipairs(t:clients()) do
      if not c.sticky then
        add_client(c,screen)
      end
    end
    for c,_ in pairs(sticky) do
      add_client(c,screen)
    end
  end
end

-- Reload the tag
local function tag_screen_changed(t)
  if not t.selected then return end
  local screen = tag.getscreen(t)
  load_clients(t)
end

-- Unselect the old focussed client
local function unfocus(c)
  local item = _cache[c]
  if item and item.selected then
    item.selected = false
  end
end

-- Select the newly focussed client
local function focus(c)
  local item = _cache[c]
  if item then
    item.selected = true
  end
end

-- Remove the client from the tag
local function untagged(c,t)
  local item = _cache[c]
  local screen = tag.getscreen(t)
  if not item or not instances[screen] then return end
  local menu = instances[screen].menu
  if t.selected then
    menu:remove(item)
  end
end

-- Add and remove clients from the tasklist
local function tagged(c,t)
  if t.selected and not c.sticky then
    add_client(c,tag.getscreen(t))
  end
end

local function new(screen)
  local args = {
    select_on=radical.base.event.NEVER,
    disable_markup = true,
    fg       = beautiful.tasklist_fg or beautiful.fg_normal,
    bg       = beautiful.tasklist_bg or beautiful.fg_normal,
    underlay_style = beautiful.tasklist_underlay_style or radical.widgets.underlay.draw_arrow,
    icon_transformation = beautiful.tasklist_icon_transformation
  }
  for k,v in ipairs {"hover","urgent","minimized","focus"} do
    args["bg_"..v] = beautiful["tasklist_bg_"..v]
    args["fg_"..v] = beautiful["tasklist_fg_"..v]
    args["underlay_bg_"..v] = beautiful["tasklist_underlay_bg_"..v]
  end
  local menu = radical.flexbar(args)
--     overlay = function(data,item,cd,w,h)
--       print("foo!")
--     end,
--   }



  -- Connect to a bunch of signals
  instances[screen] = {menu = menu}

  load_clients(tag.selected(screen))

  menu:connect_signal("button::press",function(menu,item,button_id,mod)
    if module.buttons and module.buttons[button_id] then
      module.buttons[button_id](item.client,menu,item,button_id,mod)
    end
  end)

  return menu,menu._internal.layout
end

function module.item(client)
  return _cache[client]
end

-- Global callbacks
capi.client.connect_signal("property::sticky"  , sticky_callback   )
capi.client.connect_signal("property::urgent"  , urgent_callback   )
capi.client.connect_signal("unmanage"          , unmanage_callback )
capi.client.connect_signal("focus"             , focus             )
capi.client.connect_signal("unfocus"           , unfocus           )
capi.client.connect_signal("property::sticky"  , reload_underlay   )
capi.client.connect_signal("property::ontop"   , reload_underlay   )
capi.client.connect_signal("property::floating", reload_underlay   )
capi.client.connect_signal("property::name"    , reload_content    )
capi.client.connect_signal("property::icon"    , reload_content    )
capi.client.connect_signal("property::minimized", minimize_callback    )
capi.client.connect_signal("tagged"            , tagged             )
capi.client.connect_signal("untagged"          , untagged           )
capi.tag.connect_signal   ("property::screen"  , tag_screen_changed )
capi.tag.connect_signal("property::selected" , load_clients)
capi.tag.connect_signal("property::activated", load_clients)

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
