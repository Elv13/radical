local setmetatable = setmetatable
local io           = io
local ipairs       = ipairs
local tag       = require( "awful.tag"     )
local config    = require( "forgotten"        )
local menu      = require( "radical.context"  )
local listTags  = require( "radical.impl.common.tag" ).listTags
local awful = require("awful")
local radical = require("radical")
local capi = { screen = screen }

local module = {}

local aTagMenu = nil

local aTag = nil

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
--         shifty.del(aTag)
    end})

  if capi.screen.count() > 1 then
    local screenMenu = menu()
    aTagMenu:add_item({text = "Screen",sub_menu = screenMenu})

    for i=1,capi.screen.count() do
      screenMenu:add_item({text = "Screen "..i, checked = tag.getscreen(aTag) == i,button1 = function() tag_to_screen(aTag,i) end})
    end
  end

  aTagMenu:add_item({text = "Merge With", sub_menu = listTags})

  function createTagList(aScreen)
    local tagList = menu()
    local count = 0
    for _, v in ipairs(awful.tag.gettags(aScreen)) do
       tagList:add_item({text = v.name})
       count = count + 1
    end
    return tagList
  end

  aTagMenu:add_item({text = "<b>Save settings</b>"})

  local mainMenu2 = menu{layout=radical.layout.grid,column=6,}

  -- TODO port to async
  local f = io.popen('find '..config.iconPath .. "tags/ -maxdepth 1 -iname \"*.png\" -type f","r")
  local counter = 0
  while true do
    local file = f:read("*line")
    if (file == "END" or nil) or (counter > 30) then
      break
    end
    mainMenu2:add_item({ button1 = function() tag.seticon(file,aTag) end, icon = file})
    counter = counter +1
  end
  f:close()
  aTagMenu:add_item({text= "Set Icon", sub_menu = mainMenu2})

  aTagMenu:add_item({text= "Layout", sub_menu = function()

  end})

  aTagMenu:add_item({text= "Flags", sub_menu = function()

  end})
  return aTagMenu
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
