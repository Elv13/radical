local setmetatable = setmetatable
local io           = io
local menu      = require( "radical.context"  )
local beautiful = require( "beautiful" )
local com_tag = require( "radical.impl.common.tag" )
local radical = require("radical")
local extensions = require("radical.impl.taglist.extensions")
local capi = { screen = screen }
local cairo     = require("lgi"                         ).cairo
local color     = require("gears.color"                 )
local tag_list = nil

local module = {}

local aTagMenu = nil

local aTag = nil

local radius = 3
local function gen_icon(col,height)
  local img  = cairo.ImageSurface.create(cairo.Format.ARGB32, height, height)--target:create_similar(target:get_content(),width,height) 
  local cr = cairo.Context(img)
  
  cr:move_to(1,radius+1)
  cr:arc(1+radius,radius+1,radius,math.pi,3*(math.pi/2))
  cr:arc(height-radius-2,radius+1,radius,3*(math.pi/2),math.pi*2)
  cr:arc(height-radius-2,height-radius-2,radius,math.pi*2,math.pi/2)
  cr:arc(2+radius,height-radius-2,radius,math.pi/2,math.pi)
  cr:close_path()
  cr:set_source(color(beautiful.menu_fg or beautiful.fg_normal))
  cr:set_line_width(2)
  cr:stroke_preserve()
  cr:set_source(color(col))
  cr:fill()
  return img
end

local function set_color(t,col)
  local pat = col
    if beautiful.taglist_custom_color then
      pat = beautiful.taglist_custom_color(pat)
    end
    local idx,name = tag_list.register_color(pat)
    local item = tag_list.item(t)
    item["bg_"..name] = pat
    item.state[idx] = true
end

local function color_menu(t)
  if not tag_list then
    tag_list = require("radical.impl.taglist")
  end
  local m = radical.context {layout=radical.layout.grid,column=6}
  m:add_item{icon=gen_icon("#ff0000",m.item_height-4), item_layout = radical.item.layout.icon, button1 = function() set_color(t,"#ff0000") end}
  m:add_item{icon=gen_icon("#00ff00",m.item_height-4), item_layout = radical.item.layout.icon, button1 = function() set_color(t,"#00ff00") end}
  m:add_item{icon=gen_icon("#0000ff",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#ff00ff",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#ffff00",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#00ffff",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#ff0000",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#00ff00",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#0000ff",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#ff00ff",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#ffff00",m.item_height-4), item_layout = radical.item.layout.icon}
  m:add_item{icon=gen_icon("#00ffff",m.item_height-4), item_layout = radical.item.layout.icon}
  return m
end

-- My config has an icon directory path stored there, change as you like
local config = nil
if pcall(require,("forgotten")) then
  config = require("forgotten")
end

local function new(t)
  aTag = t or aTag

  if aTagMenu then return aTagMenu end

  aTagMenu = menu()

  aTagMenu:add_item({text = "Visible", checked = true,button1 = function() aTag.selected = not aTag.selected end})
  aTagMenu:add_item({text = "Rename", button1 = function() --[[shifty.rename(aTag)]] end})

  aTagMenu:add_item({text = "Close applications and remove", button1 = function()
    for i=1, #aTag:clients() do
        aTag:clients()[i]:kill()
    end
  end})

  if capi.screen.count() > 1 then
    local screenMenu = menu()
    aTagMenu:add_item({text = "Screen",sub_menu = screenMenu})

    for i=1,capi.screen.count() do
      screenMenu:add_item({text = "Screen "..i, checked = aTag.screen == i,button1 = function() --[[tag_to_screen(aTag,i)]] end})
    end
  end

  aTagMenu:add_item({text = "Set color", sub_menu = function() return color_menu(aTag) end})
  aTagMenu:add_item({text = "Merge With", sub_menu = function() return com_tag.listTags() end})
  aTagMenu:add_item({text = "<b>Save settings</b>"})

  local mainMenu2 = menu{layout=radical.layout.grid,column=6,}

  -- TODO port to async
  local f = io.popen('find '..config.iconPath .. "tags_invert/ -maxdepth 1 -iname \"*.png\" -type f","r")
  local counter = 0
  while true do
    local file = f:read("*line")
    if (file == "END" or nil) or (counter > 30) then
      break
    end
    mainMenu2:add_item({ button1 = function() aTag.icon = file end, icon = file, item_layout = radical.item.layout.icon})
    counter = counter +1
  end
  f:close()
  aTagMenu:add_item({text= "Set Icon", sub_menu = mainMenu2})

  aTagMenu:add_item({text= "Layout", sub_menu = function()
    local m = radical.context({filter=false,item_style=radical.item.style.rounded,item_height=30,column=4,layout=radical.layout.grid})
    return com_tag.layouts(m)
  end})

  aTagMenu:add_item({text= "Flags", sub_menu = function()

  end})
  aTagMenu:add_item({text= "Add widgets", sub_menu = function()
    return extensions.extensions_menu(aTag)
  end})
  return aTagMenu
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
