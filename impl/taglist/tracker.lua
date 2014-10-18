-- This module try to track tags relative index
-- It will emit signals the widget can rely on 
local capi = {tag=tag}
local tag    = require( "awful.tag"      )
local object = require( "radical.object" )
local awful = require("awful")

local cache = {}
local init = false
local screen_cache = setmetatable({}, { __mode = 'k' })--TODO this suck

local function reload(t,s)
  local s        = s or tag.getscreen(t) or screen_cache[t]
  local tracker  = cache[s]

  if not tracker then return end

  local old_tags = tracker._internal.old_tags or {}

  local new_tags = tag.gettags(s)
  for k,v in ipairs(new_tags) do
    if v ~= old_tags[k] then
--       print(v.name,k,s,tag.getscreen(v),tag.getidx(v))
      v:emit_signal("property::index2",k)
      screen_cache[v] = s
    end
  end
  tracker._internal.old_tags = new_tags
end

--[[awful.tag.setscreen = function(t, s)
  if not tag or type(t) ~= "tag" or not s then return end

  -- Keeping the old index make very little sense when chaning screen
  awful.tag.setproperty(t, "index", nil)

  local old_screen = awful.tag.getproperty(t,"screen")

  -- Change the screen
  awful.tag.setproperty(t, "screen", s)

  --Prevent some very strange side effects, does create some issue with multitag clients
  for k,c in ipairs(t:clients()) do
      c.screen = s --Move all clients
      c:tags({t})
  end
  awful.tag.history.restore(old_screen,1)
end]]--

local function new(s)
  if cache[s] then return cache[s] end

  local tracker,private_data = object({
    private_data = {
      widget = widget,
      selected = false,
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })
  tracker._internal = {}

  cache[s] = tracker

  if not init then
    capi.tag.connect_signal("property::screen"   , reload )
    capi.tag.connect_signal("property::activated", reload )
    capi.tag.connect_signal("property::index"    , reload )
  end

  tracker.reload = function()
    reload(nil,s)
  end

  return tracker
end


capi.tag.add_signal("property::index2")


return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
