---------------------------------------------------------------------------
-- @author Emmanuel Lepage Vallee <elv1313@gmail.com>
-- @copyright 2014 Emmanuel Lepage Vallee
-- @release devel
-- @license BSD
---------------------------------------------------------------------------

local capi = {tag=tag,client=client,screen=screen}

local radical   = require( "radical"      )
local tag       = require( "awful.tag"    )
local beautiful = require( "beautiful"    )
local color     = require( "gears.color"  )
local client    = require( "awful.client" )
local wibox     = require( "wibox"        )
local awful     = require( "awful"        )


local module,instances = {},{}

-- The cache can be global, this is unsupported by Radical, but for now it
-- doesn't cause too many issues. This make it easier to track state
local cache = setmetatable({}, { __mode = 'k' })


module.buttons = { [1] = awful.tag.viewonly,
                      [2] = awful.tag.viewtoggle,
                      [3] = function(q,w,e,r)
                              print("hello",q,q._item,q.item)
                              local menu = customMenu.tagOption.getMenu()
                              menu.visible = true
                            end,
                      [4] = function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end,
                      [5] = function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end,
                    }
--                     awful.button({ modkey }, 1, awful.client.movetotag),
--                     awful.button({ modkey }, 3, awful.client.toggletag),



local function index_draw(self,w, cr, width, height)
  cr:save()
  cr:set_source(color(beautiful.bg_normal))
  local d = wibox.widget.textbox._draw or wibox.widget.textbox.draw
  d(self,wibox, cr, width, height)
  cr:restore()
end

local function create_item(t,s)
  local menu = instances[s]
  if not menu then return end
  local w = wibox.layout.fixed.horizontal()
  local icon =  tag.geticon(t)
  local ib = wibox.widget.imagebox()
  ib:set_image(icon)
  w:add(ib)
  local tw = wibox.widget.textbox()
  tw.draw = index_draw
--   tw:set_fg("#000000")
  tw:set_markup(" <b>"..(menu.rowcount+1).."</b> ")
  w:add(tw)
  local item = menu:add_item { text = t.name, prefix_widget = w}
  item:connect_signal("index::changed",function(_,value)
    tw:set_markup(" <b>"..(item.index).."</b> ")
  end)

  menu:connect_signal("button::press",function(menu,item,button_id,mod)
    if module.buttons and module.buttons[button_id] then
      module.buttons[button_id](item.client,menu,item,button_id,mod)
    end
  end)

  item._internal.screen = s
--   item.state[radical.base.item_flags.USED    ] = #t:clients() > 0
  item.state[radical.base.item_flags.SELECTED] = t.selected or nil
  cache[t] = item
  item.tag = t
  return item
end

local function track_used(c,t)
  if t then
    local item = cache[t] or create_item(t,tag.getscreen(t))
    if not item then return end -- Yes, it happen if the screen is still nil
    item.state[radical.base.item_flags.USED] = #t:clients() > 0
    item.state[radical.base.item_flags.CHANGED] = not t.selected
  end
end

local function tag_activated(t)
  if not t.activated and cache[t] then
    instances[cache[t]._internal.screen]:remove(cache[t])
    cache[t] = nil
  end
end

local function tag_added(t,b)
  if t then
    local s = tag.getscreen(t)
    if not cache[t] then
      create_item(t,s)
    elseif cache[t]._internal.screen ~= s then
      instances[cache[t]._internal.screen]:remove(cache[t])
      instances[s]:append(cache[t])
      cache[t]._internal.screen = s
    end
  end
end

local function select(t)
  local s = t.selected
  local item = cache[t] or create_item(t,tag.getscreen(t))
  if item then
    item.state[radical.base.item_flags.SELECTED] = s or nil
    if s then
      item.state[radical.base.item_flags.CHANGED] = nil
      item.state[radical.base.item_flags.URGENT] = nil
    end
  end
end

capi.tag.add_signal("property::urgent")
local function urgent_callback(c)
    local modif = c.urgent == true and 1 or -1
    for k,t in ipairs(c:tags()) do
        local current = (awful.tag.getproperty(t,"urgent") or 0)
        local item = cache[t] or create_item(t,tag.getscreen(t))
        if current + modif < 0 then
            awful.tag.setproperty(t,"urgent",0)
            item.state[radical.base.item_flags.URGENT] = nil
        else
            awful.tag.setproperty(t,"urgent",current + modif)
            if not t.selected then
              item.state[radical.base.item_flags.URGENT] = true
            end
        end
    end
end

local is_init = false
local function init()
  if is_init then return end

  -- Global signals
  capi.client.connect_signal("tagged", track_used)
  capi.client.connect_signal("untagged", track_used)
  capi.client.connect_signal("unmanage", track_used)
  capi.client.connect_signal("property::urgent"  , urgent_callback   )
  capi.tag.connect_signal("property::activated",tag_activated)
  capi.tag.connect_signal("property::screen", tag_added)

  -- Property bindings
  capi.tag.connect_signal("property::name", function(t)
    local item = cache[t]
    if item then
      item.text = t.name
    end
  end)
  capi.tag.connect_signal("property::icon", function(t)
    local item = cache[t]
    if item then
      item.icon = tag.geticon(t)
    end
  end)
  is_init = true
end

local function new(s)
  instances[s] = radical.bar {
    select_on  = radical.base.event.NEVER,
    fg         = beautiful.fg_normal,
    bg_focus   = beautiful.taglist_bg_image_selected2,
    item_style = radical.item.style.arrow_prefix,
    bg_hover   = beautiful.menu_bg_focus,
    bg_used    = beautiful.taglist_bg_image_used2,
    bg_urgent  = beautiful.taglist_bg_image_urgent2,
    bg_changed = beautiful.taglist_bg_image_changed,
--     fkeys_prefix = true,
  }


  -- Load the innitial set of tags
  for k,t in ipairs(tag.gettags(s)) do
    create_item(t,s)
  end

  -- Per screen signals
--   tag.attached_connect_signal(s, "property::selected", tag_added)
--   tag.attached_connect_signal(screen, "property::hide", ut)
--   tag.attached_connect_signal(s, "property::index", tag_added)

  instances[s]:connect_signal("button::press",function(m,item,button_id,mod)
    if module.buttons and module.buttons[button_id] then
      module.buttons[button_id](item.tag,m,item,button_id,mod)
    end
  end)

  init()
  return instances[s]
end

capi.tag.connect_signal("property::selected" , select)


return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
