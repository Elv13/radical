---------------------------------------------------------------------------
-- @author Emmanuel Lepage Vallee <elv1313@gmail.com>
-- @copyright 2014 Emmanuel Lepage Vallee
-- @release devel
-- @note Based on the original tasklist.lua
-- @license GPLv2+ because of copy paste from the old tasklist.lua
---------------------------------------------------------------------------

local capi = {client = client,tag=tag,screen=screen}
local radical     = require( "radical"      )
local tag         = require( "awful.tag"    )
local beautiful   = require( "beautiful"    )
local client      = require( "awful.client" )
local wibox       = require( "wibox"        )
local surface     = require( "gears.surface")
local client_menu = require( "radical.impl.tasklist.client_menu")
local theme       = require( "radical.theme")
local rad_client  = require( "radical.impl.common.client")
local shape = require("gears.shape")

local sticky,urgent,instances,module = {extensions=require("radical.impl.tasklist.extensions")},{},{},{}
local _cache = setmetatable({}, { __mode = 'k' })
local MINIMIZED = 6.5
theme.register_color(MINIMIZED , "minimized" , "tasklist_minimized" , true )

-- Default button implementation
module.buttons = {
  [1] = function(c,menu,item,button_id,mod, geo)
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
  [3] = function(c,menu,item,button_id,mod, geo)
    client_menu.client = c
    local m = client_menu()
--     menu.parent_geometry = geo
    m.visible = not m.visible
    m._internal.w:move_by_parent(nil, "cursor")
  end,
  [4] = function(c,menu,item,button_id,mod, geo)
    client.focus.byidx(1)
    if capi.client.focus then capi.client.focus:raise() end
  end,
  [5] = function(c,menu,item,button_id,mod, geo)
    client.focus.byidx(-1)
    if capi.client.focus then capi.client.focus:raise() end
  end
}

local function display_screenshot(c,geo,visible)
    if not c then return end

    local dgeo = geo.drawable.drawable:geometry()

    -- The geometry is a mix of the drawable and widget one
    local geo2 = {
      x        = dgeo.x + geo.x,
      y        = dgeo.y + geo.y,
      width    = geo.width     ,
      height   = geo.height    ,
      drawable = geo.drawable  ,
    }

    return rad_client.screenshot(c,geo2)
end

local function sticky_callback(c)
  local val = c.sticky
  sticky[c] = val and true or nil
  local menu = instances[capi.screen[c.screen]].menu
  local is_in_tag = false
  for _,t in ipairs(tag.selectedlist(c.screen)) do
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

local infoshape_template = {
    ontop = {
        text  = "ontop",
        shape = shape.hexagon,
        bg    =  beautiful.tasklist_bg_underlay,
    },
    float = {
        text  = "float",
        shape = shape.hexagon,
        bg    =  beautiful.tasklist_bg_underlay,
    },
    sticky = {
        text  = "sticky",
        shape = shape.hexagon,
        bg    =  beautiful.tasklist_bg_underlay,
    },
}

-- Reload <float> <ontop> and <sticky> labels
local function reload_infoshapes(c)
    local item = _cache[c]

    local infoshapes = {}

    if item then
        if c.ontop then
            infoshapes[#infoshapes+1] = infoshape_template.ontop
        end
        if c.floating then
            infoshapes[#infoshapes+1] = infoshape_template.float
        end
        if c.sticky then
            infoshapes[#infoshapes+1] = infoshape_template.sticky
        end

        item.infoshapes = infoshapes

        item.widget:emit_signal("widget::updated")
    end
end

-- Reload title and icon
local function reload_content(c,b,a)
  local item = _cache[c]
  if item then
--     if not beautiful.tasklist_disable_icon then
--       item.icon = surface(c.icon) or beautiful.tasklist_default_icon
--     end
    item.text = c.name or "N/A"
  end
end


local function create_client_item(c,screen)
  local item = _cache[c]
  local menu = instances[capi.screen[screen]].menu
  -- If it already exist, don't waste time creating a copy
  if item then
    menu:append(item)
    return item
  end

  -- Too bad, let's create a new one
  local suf_w = wibox.layout.fixed.horizontal()

  item = menu:add_item{
    text=c.name,
    icon=(not beautiful.tasklist_disable_icon) and surface(c.icon),
    suffix_widget=suf_w
  }
  item.state[radical.base.item_flags.USED] = true

  if c.minimized then
    item.state[MINIMIZED] = true
  end

--   item:connect_signal("mouse::enter", function()
--     item.infoshapes = {
--         {text = "1:23:45", bg = beautiful.tasklist_bg_overlay, align = "center"},
--         {text = c.pid    , bg = beautiful.tasklist_bg_overlay, align = "center"}
--     }
--   end)
  item:connect_signal("mouse::leave", function()
--     item.infoshapes = {}
  end)

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
    reload_infoshapes(c)
    if capi.client.focus == c then
      ret.selected = true
    end
  end
end

-- Clear the menu and repopulate it
local function load_clients(t)
  if not t then return end

  local screen = t.screen
  if not t or not screen or not instances[capi.screen[screen]] then return end
  local menu = instances[capi.screen[screen]].menu
  local clients = {}
  local selected = screen.selected_tags
  -- The "#selected > 0" is for reseting when multiple tags are selected
  if t.selected or #selected > 0 then
    menu:clear()
    for k2,t2 in ipairs(selected) do
      for k, c in ipairs(t2:clients()) do
        if not c.sticky then
          add_client(c,screen)
          clients[#clients+1] = c
        end
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

  -- t.screen can be nil if the tag was deleted
  local screen = t.screen or c.screen or capi.mouse.screen
  if not item or not instances[capi.screen[screen]] then return end
  local menu = instances[capi.screen[screen]].menu
  if t.selected then
    menu:remove(item)
  end
end

-- Add and remove clients from the tasklist
local function tagged(c,t)
  if t.selected and not c.sticky then
    add_client(c,t.screen)
  end
end

local function new(screen)
  local args = {
    select_on            = radical.base.event.NEVER                                                      ,
    disable_markup       = true                                                                          ,
    fg                   = beautiful.tasklist_fg                   or beautiful.fg_normal                ,
    bg                   = beautiful.tasklist_bg                   or beautiful.bg_normal                ,
--     overlay_bg           = beautiful.tasklist_bg_overlay                                                 ,
    icon_transformation  = beautiful.tasklist_icon_transformation                                        ,
    default_item_margins = beautiful.tasklist_default_item_margins                                       ,
    default_margins      = beautiful.tasklist_default_margins                                            ,
    item_style           = beautiful.tasklist_item_style                                                 ,
    style                = beautiful.tasklist_style                                                      ,
    spacing              = beautiful.tasklist_spacing                                                    ,
    icon_per_state       = true                                                                          ,
    item_border_color    = beautiful.tasklist_item_border_color                                          ,
    item_border_width    = beautiful.tasklist_item_border_width                                          ,
  }
  for k,v in ipairs {"hover","urgent","minimized","focus","used"} do
    args["bg_"..v] = beautiful["tasklist_bg_"..v]
    args["bgimage_"..v] = beautiful["tasklist_bgimage_"..v]
    args["fg_"..v] = beautiful["tasklist_fg_"..v]
    args["border_color_"..v] = beautiful["tasklist_border_color_"..v]
    args["underlay_bg_"..v] = beautiful["tasklist_underlay_bg_"..v]
  end
  local menu = radical.flexbar(args)
--     overlay = function(data,item,cd,w,h)
--       print("foo!")
--     end,
--   }



  -- Connect to a bunch of signals
  instances[capi.screen[screen]] = {menu = menu}

  load_clients(screen.selected_tag)

  menu:connect_signal("button::press",function(_,item,button_id,mod,geo)
    if module.buttons and module.buttons[button_id] then
      module.buttons[button_id](item.client,menu,item,button_id,mod,geo)
    end
  end)

  menu:connect_signal("long::hover",function(m,i,mod,geo)
    display_screenshot(i.client,geo,true)
  end)

  return menu,menu._internal.widget
end

function module.item(c)
  return _cache[c]
end

-- Global callbacks
capi.client.connect_signal("property::sticky"   , sticky_callback    )
capi.client.connect_signal("property::urgent"   , urgent_callback    )
capi.client.connect_signal("unmanage"           , unmanage_callback  )
capi.client.connect_signal("focus"              , focus              )
capi.client.connect_signal("unfocus"            , unfocus            )
capi.client.connect_signal("property::sticky"   , reload_infoshapes    )
capi.client.connect_signal("property::ontop"    , reload_infoshapes    )
capi.client.connect_signal("property::floating" , reload_infoshapes    )
capi.client.connect_signal("property::name"     , reload_content     )
capi.client.connect_signal("property::icon"     , reload_content     )
capi.client.connect_signal("property::minimized", minimize_callback  )
capi.client.connect_signal("tagged"             , tagged             )
capi.client.connect_signal("untagged"           , untagged           )
capi.tag.connect_signal   ("property::screen"   , tag_screen_changed )
capi.tag.connect_signal   ("property::selected" , load_clients       )
capi.tag.connect_signal   ("property::activated", load_clients       )

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
