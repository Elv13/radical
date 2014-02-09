---------------------------------------------------------------------------
-- @author Emmanuel Lepage Vallee <elv1313@gmail.com>
-- @copyright 2014 Emmanuel Lepage Vallee
-- @release devel
-- @note Based on the original tasklist.lua
-- @license GPLv2+ because of copy paste from the old tasklist.lua
---------------------------------------------------------------------------

local capi = {client = client}
local radical   = require( "radical"      )
local tag       = require( "awful.tag"    )
local beautiful = require( "beautiful"    )
local client    = require( "awful.client" )

local sticky,urgent,instances,module = {},{},{},{}

local function sticky_callback(c)
  local val = c.sticky
  sticky[c] = val and true or nil
  for k,v in ipairs(instances) do
    if val then
      v.menu:append(v.cache[c])
    else
      v.menu:remove(v.cache[c])
    end
  end
end

local function urgent_callback(c)
  local val = c.urgent
  urgent[c] = val and true or nil
end

local function unmanage_callback(c)
  sticky[c] = nil
  urgent[c] = nil
  for k,v in ipairs(instances) do
    v.menu:remove(v.cache[c])
    v.cache[c] = nil
  end
end

-- Reload <float> <ontop> and <sticky> labels
local function reload_underlay(c)
  local cache = instances[c.screen].cache
  local udl,item = {},cache[c]
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

local function create_client_item(c,screen)
  local cache = instances[screen].cache
  local menu = instances[screen].menu
  -- If it already exist, don't waste time creating a copy
  if cache[c] then
    return menu:append(cache[c])
  end

  -- Too bad, let's create a new one
  cache[c] = menu:add_item{text=c.name,icon=c.icon,button1=function()
    capi.client.focus = c
    c:raise()
  end}
  return cache[c]
end

local function add_client(c,screen)
  if not (c.skip_taskbar or c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop") and c.screen == screen then
    local ret = create_client_item(c,screen)
    reload_underlay(c)
    if c.focus == c then
      ret.selected = true
    end
  end
end

-- Unselect the old focussed client
local function unfocus(c)
  local cache = instances[c.screen].cache
  local item = cache[c]
  if item and item.selected then
    item.selected = false
  end
end

-- Select the newly focussed client
local function focus(c)
  local cache = instances[c.screen].cache
  local item = cache[c]
  if item then
    item.selected = true
  end
end

local function new(screen)
  local cache,menu = setmetatable({}, { __mode = 'k' }),radical.flexbar {
    select_on=radical.base.event.NEVER,
    fg       = beautiful.fg_normal,
    bg_focus = beautiful.taglist_bg_image_selected2 or beautiful.bg_focus
  }

  -- Clear the menu and repopulate it
  local function load_clients(t)
    if not t then return end
    if t.selected and tag.getscreen(t) == screen then
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

  -- Add and remove clients from the tasklist
  local function tagged(c,t)
    if t.selected and not c.sticky and tag.getscreen(t) == screen then
      add_client(c,screen)
    end
  end
  local function untagged(c,t)
    local item = cache[c]
    if t.selected and tag.getscreen(t) == screen then
      menu:remove(item)
    end
  end

  -- Connect to a bunch of signals
  tag.attached_connect_signal(screen, "property::selected" , load_clients)
  tag.attached_connect_signal(screen, "property::activated", load_clients)
  capi.client.connect_signal("tagged"            , tagged            )
  capi.client.connect_signal("untagged"          , untagged          )

  instances[screen] = {menu = menu, cache = cache }

  load_clients(tag.selected(screen))

  return menu
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

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
