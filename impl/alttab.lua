local setmetatable,type = setmetatable, type
local ipairs, pairs     = ipairs, pairs
local button    = require( "awful.button" )
local beautiful = require( "beautiful"    )
local tag       = require( "awful.tag"    )
local menu      = require( "radical.box"  )
local util      = require( "awful.util"   )
local wibox     = require( "wibox"        )
local color     = require( "gears.color"  )
local capi = { client = client, mouse = mouse, screen = screen,}
local print = print

local module,pause_monitoring = {},false

local function draw_underlay(text)
  -- If blind is installed, it can be used to draw the tag(s) name in the background
  return beautiful.draw_underlay and beautiful.draw_underlay(text) or nil
end

-- Keep its own history instead of using awful.client.focus.history
local focusIdx,focusTable = 1,setmetatable({}, { __mode = 'v' })
local function push_focus(c)
  if not pause_monitoring then
    focusTable[c] = focusIdx
    focusIdx = focusIdx + 1
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
  local c        = args.client
  local field    = args.field
  local focus    = args.focus or false
  local checked  = args.checked or false
  local widget   = wibox.widget.imagebox()


  local curfocus  = ((((type(focus) == "function") and focus() or focus) == true) and "focus" or "normal")
  local curactive = ((((type(checked) == "function") and checked() or checked) == true) and "active" or "inactive")
  widget:set_image( module.titlebar_path.. field .."_"..curfocus .."_"..curactive..".png"  )
  widget:buttons( util.table.join(button({ }, 1 , args.onclick)))

  return widget
end

local function select_next(menu)
  local item = menu.next_item
  item.selected = true
  item.button1()
  return true
end

local function new(screen, args)
  local currentMenu = menu({filter = true, show_filter=true, autodiscard = true,
    disable_markup=true,fkeys_prefix=true,width=(((screen or capi.screen[capi.mouse.screen]).geometry.width)/2)})

  currentMenu:add_key_hook({}, "Tab", "press", select_next)

  if args and args.auto_release then
    currentMenu:add_key_hook({}, "Alt_L", "release", function(_)
      currentMenu.visible = false
      return false
    end)
  end

  if module.titlebar_path then
    for k,v2 in ipairs(get_history(screen)) do
      local l,v = wibox.layout.fixed.horizontal(),v2[2]
      l:add( button_group({client = v, width=5, field = "close",     focus = false, checked = false                            , onclick = function() v:kill() end                      }))
      l:add( button_group({client = v, width=5, field = "ontop",     focus = false, checked = function() return v.ontop end    , onclick = function() v.ontop = not v.ontop end         }))
      l:add( button_group({client = v, width=5, field = "maximized", focus = false, checked = function() return v.maximized end, onclick = function() v.maximized = not v.maximized end }))
      l:add( button_group({client = v, width=5, field = "sticky",    focus = false, checked = function() return v.sticky end   , onclick = function() v.sticky = not v.sticky end       }))
      l:add( button_group({client = v, width=5, field = "floating",  focus = false, checked = function() return v.floating end , onclick = function() v.floating = not v.floating end   }))

      l.fit = function (s,w,h) return 5*h,h end
      currentMenu:add_item({
        text    = v.name,
        button1 = function()
          if v:tags()[1] and v:tags()[1].selected == false then
            tag.viewonly(v:tags()[1])
          end
          capi.client.focus = v
        end,
        icon    = module.icon_transform and module.icon_transform(v.icon or module.default_icon) or v.icon or module.default_icon,
        suffix_widget = l,
        selected = capi.client.focus == v,
        underlay = v:tags()[1] and draw_underlay(v:tags()[1].name)
      })
    end
  end

  pause_monitoring,currentMenu.visible = true, true
  if args.auto_release then
    select_next(currentMenu)
  end
  currentMenu:connect_signal("visible::changed",function(m)
    if not m.visible then pause_monitoring = false;push_focus(capi.client.focus) end
  end)
  return currentMenu
end

function module.altTab(args)
  new(nil,{leap = 1,auto_release = (args or {}).auto_release})
end

function module.altTabBack(args)
  new(nil,{leap = -1,auto_release = (args or {}).auto_release})
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
