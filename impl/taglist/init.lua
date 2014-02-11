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
local client    = require( "awful.client" )


local module,instances = {},{}

local state = {
  INNACTIVE = 0,
  ACTIVE    = 1, --[aka: EMPTY]
  USED      = 2,
  SELECTED  = 3,
  URGENT    = 4,
}

-- The cache can be global, this is unsupported by Radical, but for now it
-- doesn't cause too many issues. This make it easier to track state
local cache = setmetatable({}, { __mode = 'k' })

local function create_item(t,s)
  local item = instances[s]:add_item { text = t.name, icon = tag.geticon(t), button1 = function()
    tag.viewonly(t)
  end}
  item._internal.set_map.used = function(value)
    local item_style = item.item_style or instances[s].item_style
    item_style(instances[s],item,{value and radical.base.item_flags.USED or nil,item.selected and 1 or nil})
  end
  item._internal.screen = s
  cache[t] = item
  return item
end

local function track_used(c,t)
  if t then
    local item = cache[t] or create_item(t,tag.getscreen(t))
    item.used = #t:clients()
  else
    for _,t2 in ipairs(c:tags()) do
      cache[t2].used = #t2:clients()
    end
  end
end

local function tag_added(t)
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

local function new(s)
  instances[s] = radical.bar {
    select_on  = radical.base.event.NEVER,
    fg         = beautiful.fg_normal,
    bg_focus   = beautiful.taglist_bg_image_selected2 or beautiful.bg_focus,
    item_style = radical.item_style.arrow_prefix,
    bg_hover   = beautiful.menu_bg_focus
  }


  -- Load the innitial set of tags
  for k,t in ipairs(tag.gettags(s)) do
    create_item(t,s)
  end

  -- Per screen signals
  tag.attached_connect_signal(screen, "property::selected", tag_added)
--   tag.attached_connect_signal(screen, "property::icon", ut)
--   tag.attached_connect_signal(screen, "property::hide", ut)
--   tag.attached_connect_signal(screen, "property::name", ut)
  tag.attached_connect_signal(screen, "property::activated", tag_added)
  tag.attached_connect_signal(screen, "property::screen", tag_added)
  tag.attached_connect_signal(screen, "property::index", tag_added)

  return instances[s]
end

-- Global signals
capi.client.connect_signal("tagged", track_used)
capi.client.connect_signal("untagged", track_used)
capi.client.connect_signal("unmanage", track_used)

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
