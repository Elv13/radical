local setmetatable = setmetatable
local radical   = require( "radical"    )
local beautiful = require( "beautiful"  )
local awful     = require( "awful"      )
local wibox     = require( "wibox"      )
local listTags  = require( "radical.impl.common.tag" ).listTags
local singalMenu = require( "radical.impl.common.client" ).signals
local extensions = require("radical.impl.tasklist.extensions")

local module,mainMenu = {},nil

local function createNewTag()
  return awful.tag.add(module.client.class,{})
end

local above,below,ontop,normal
local function layer_button1()
  above.checked  = module.client.above
  ontop.checked  = module.client.ontop
  below.checked  = module.client.below
  normal.checked = not (module.client.above or module.client.ontop or module.client.below)
end
local layer_m = nil
local function layerMenu()
  if layer_m then
    return layer_m
  end
  layer_m = radical.context{}

  normal = layer_m:add_item({text="Normal"       , checked=true , button1 = function()
    module.client.above = false
    module.client.below = false
    module.client.ontop = false
    layer_button1()
  end})
  above = layer_m:add_item({text="Above"       , checked=true , button1 = function()
    module.client.above = not module.client.above
    layer_button1()
  end})
  below = layer_m:add_item({text="Below"       , checked=true , button1 = function()
    module.client.below = not module.client.below
    layer_button1()
  end})
  ontop = layer_m:add_item({text="On Top"      , checked=true , button1 = function()
    module.client.ontop = not module.client.ontop
    layer_button1()
  end})
  layer_button1()

  return layer_m
end

local function new(screen, args)
  if mainMenu then
    layer_button1()
    return mainMenu
  end
  mainMenu = radical.context()
  local itemVisible,itemVSticky,itemVFloating,itemMaximized

  itemVisible    = mainMenu:add_item{
    text    = "Visible",
    checked = function() if module.client ~= nil then return not module.client.hidden else return false end end,
    button1 = function()
      module.client.minimized =  not module.client.minimized
      itemVisible.checked     = not module.client.minimized
    end
  }
  itemVSticky    = mainMenu:add_item{
    text    = "Sticky",
    checked = function() if module.client ~= nil then return module.client.sticky else return false end end,
    button1 = function()
      module.client.sticky = not module.client.sticky
      itemVSticky.checked  = module.client.sticky
    end
  }
  itemVFloating  = mainMenu:add_item{
    text    = "Floating",
    checked = true ,
    button1 = function()
      module.client.floating = not module.client.floating
      itemVFloating.checked = module.client.floating
    end
  }
  itemMaximized  = mainMenu:add_item{
    text    = "Fullscreen",
    checked = true,
    button1 = function()
      module.client.fullscreen = not module.client.fullscreen
      itemMaximized.checked    = module.client.fullscreen 
    end
  }
  mainMenu:add_item{text="Move to tag"       , sub_menu = function() return listTags() end,}
  mainMenu:add_item{text="Send Signal"       , sub_menu = singalMenu()                    ,}
  mainMenu:add_item{text="Renice"            , checked  = true , button1 = function()  end,}
  mainMenu:add_item{text="Move to a new Tag" , button1  = function()
    local t = createNewTag()
    module.client:tags({t})
    awful.tag.viewonly(t)
    mainMenu.visible = false
  end}

  mainMenu:add_item({text="Layer"       , sub_menu=layerMenu(), button1 = function()  end})
  mainMenu:add_item{text="Add widgets",sub_menu=function() return extensions.extensions_menu(module.client) end}
  mainMenu:add_widget(radical.widgets.separator())

  local ib = wibox.widget.imagebox()
  ib:set_image(beautiful.titlebar_close_button_normal)
  mainMenu:add_item({text="Close",suffix_widget = ib, button1 = function() if module.client ~= nil then  module.client:kill();mainMenu.visible=false end end})

  return mainMenu
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
