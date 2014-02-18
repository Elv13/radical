local capi = { screen = screen, }
local setmetatable = setmetatable
local ipairs,pairs = ipairs,pairs
local type         = type
local radical   = require( "radical"    )
local beautiful = require( "beautiful"  )
local awful     = require( "awful"      )
local util      = require( "awful.util" )
local wibox     = require( "wibox"      )

local module,mainMenu = {},nil

local function listTags()
  function createTagList(aScreen)
    local tagList = radical.context({autodiscard = true})
    for _, v in ipairs(awful.tag.gettags(aScreen)) do
      tagList:add_item({text = v.name,icon=awful.tag.geticon(v)})
    end
    return tagList
  end
  if capi.screen.count() == 1 then
    return createTagList(1)
  else
    local screenSelect = radical.context(({autodiscard = true}))
    for i=1, capi.screen.count() do
      screenSelect:add_item({text="Screen "..i , sub_menu = createTagList(i)})
    end
    return screenSelect
  end
end

local function createNewTag()
  return awful.tag.add(module.client.class,{})
end

local sigMenu = nil
local function singalMenu()
  if sigMenu then
    return sigMenu
  end
  sigMenu       = radical.context{max_items=10}
  sigterm       = sigMenu:add_item({text="SIGTERM"   , button1 = function() util.spawn("kill -s TERM    "..module.client.pid) end,underlay="15"})
  sigkill       = sigMenu:add_item({text="SIGKILL"   , button1 = function() util.spawn("kill -s KILL    "..module.client.pid) end,underlay="9"})
  sigint        = sigMenu:add_item({text="SIGINT"    , button1 = function() util.spawn("kill -s INT     "..module.client.pid) end,underlay="2"})
  sigquit       = sigMenu:add_item({text="SIGQUIT"   , button1 = function() util.spawn("kill -s QUIT    "..module.client.pid) end,underlay="3"})
--     sigMenu:add_widget(radical.widgets.separator())
  sig0          = sigMenu:add_item({text="SIG0"      , button1 = function() util.spawn("kill -s 0       "..module.client.pid) end,underlay=nil})
  sigalrm       = sigMenu:add_item({text="SIGALRM"   , button1 = function() util.spawn("kill -s ALRM    "..module.client.pid) end,underlay="14"})
  sighup        = sigMenu:add_item({text="SIGHUP"    , button1 = function() util.spawn("kill -s HUP     "..module.client.pid) end,underlay="1",tooltip="sdfsdfsdf"})
  sigpipe       = sigMenu:add_item({text="SIGPIPE"   , button1 = function() util.spawn("kill -s PIPE    "..module.client.pid) end,underlay="13"})
  sigpoll       = sigMenu:add_item({text="SIGPOLL"   , button1 = function() util.spawn("kill -s POLL    "..module.client.pid) end,underlay=nil})
  sigprof       = sigMenu:add_item({text="SIGPROF"   , button1 = function() util.spawn("kill -s PROF    "..module.client.pid) end,underlay="27"})
  sigusr1       = sigMenu:add_item({text="SIGUSR1"   , button1 = function() util.spawn("kill -s USR1    "..module.client.pid) end,underlay="10"})
  sigusr2       = sigMenu:add_item({text="SIGUSR2"   , button1 = function() util.spawn("kill -s USR2    "..module.client.pid) end,underlay="12"})
  sigsigvtalrm  = sigMenu:add_item({text="SIGVTALRM" , button1 = function() util.spawn("kill -s VTALRM  "..module.client.pid) end,underlay=nil})
  sigstkflt     = sigMenu:add_item({text="SIGSTKFLT" , button1 = function() util.spawn("kill -s STKFLT  "..module.client.pid) end,underlay=nil})
  sigpwr        = sigMenu:add_item({text="SIGPWR"    , button1 = function() util.spawn("kill -s PWR     "..module.client.pid) end,underlay=nil})
  sigwinch      = sigMenu:add_item({text="SIGWINCH"  , button1 = function() util.spawn("kill -s WINCH   "..module.client.pid) end,underlay=nil})
  sigchld       = sigMenu:add_item({text="SIGCHLD"   , button1 = function() util.spawn("kill -s CHLD    "..module.client.pid) end,underlay="17"})
  sigurg        = sigMenu:add_item({text="SIGURG"    , button1 = function() util.spawn("kill -s URG     "..module.client.pid) end,underlay=nil})
  sigtstp       = sigMenu:add_item({text="SIGTSTP"   , button1 = function() util.spawn("kill -s TSTP    "..module.client.pid) end,underlay=nil})
  sigttin       = sigMenu:add_item({text="SIGTTIN"   , button1 = function() util.spawn("kill -s TTIN    "..module.client.pid) end,underlay="21"})
  sigttou       = sigMenu:add_item({text="SIGTTOU"   , button1 = function() util.spawn("kill -s TTOU    "..module.client.pid) end,underlay="22"})
  sigstop       = sigMenu:add_item({text="SIGSTOP"   , button1 = function() util.spawn("kill -s STOP    "..module.client.pid) end,underlay="17"})
  sigcont       = sigMenu:add_item({text="SIGCONT"   , button1 = function() util.spawn("kill -s CONT    "..module.client.pid) end,underlay="18"})
  sigabrt       = sigMenu:add_item({text="SIGABRT"   , button1 = function() util.spawn("kill -s ABRT    "..module.client.pid) end,underlay="6"})
  sigfpe        = sigMenu:add_item({text="SIGFPE"    , button1 = function() util.spawn("kill -s FPE     "..module.client.pid) end,underlay="8"})
  sigill        = sigMenu:add_item({text="SIGILL"    , button1 = function() util.spawn("kill -s ILL     "..module.client.pid) end,underlay="4"})
  sigsegv       = sigMenu:add_item({text="SIGSEGV"   , button1 = function() util.spawn("kill -s SEGV    "..module.client.pid) end,underlay="11"})
  sigtrap       = sigMenu:add_item({text="SIGTRAP"   , button1 = function() util.spawn("kill -s TRAP    "..module.client.pid) end,underlay="5"})
  sigsys        = sigMenu:add_item({text="SIGSYS"    , button1 = function() util.spawn("kill -s SYS     "..module.client.pid) end,underlay="12"})
  sigemt        = sigMenu:add_item({text="SIGEMT"    , button1 = function() util.spawn("kill -s EMT     "..module.client.pid) end,underlay=nil})
  sigbus        = sigMenu:add_item({text="SIGBUS"    , button1 = function() util.spawn("kill -s BUS     "..module.client.pid) end,underlay="7"})
  sigxcpu       = sigMenu:add_item({text="SIGXCPU"   , button1 = function() util.spawn("kill -s XCPU    "..module.client.pid) end,underlay=nil})
  sigxfsz       = sigMenu:add_item({text="SIGXFSZ"   , button1 = function() util.spawn("kill -s XFSZ    "..module.client.pid) end,underlay=nil})
  return sigMenu
end


local above,below,ontop
local function layer_button1()
  above.checked = module.client.above
  ontop.checked = module.client.ontop
  below.checked = module.client.below
end
local layer_m = nil
local function layerMenu()
  if layer_m then
    return layer_m
  end
  layer_m = radical.context{}

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
  local itemVisible,itemVSticky,itemVFloating,itemMaximized,itemMoveToTag,itemSendSignal,itemRenice,itemNewTag,itemLayer,itemClose

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
      awful.client.floating.set(module.client,not awful.client.floating.get(module.client))
      itemVFloating.checked = awful.client.floating.get(module.client)
    end
  }
  itemMaximized  = mainMenu:add_item{
    text="Fullscreen",
    checked=true,
    button1 = function()
      module.client.fullscreen = not module.client.fullscreen
      itemMaximized.checked    = module.client.fullscreen 
    end
  }
  itemMoveToTag  = mainMenu:add_item{text="Move to tag"       , sub_menu = listTags                       ,}
  itemSendSignal = mainMenu:add_item{text="Send Signal"       , sub_menu = singalMenu()                   ,}
  itemRenice     = mainMenu:add_item{text="Renice"            , checked  = true , button1 = function()  end}
  itemNewTag     = mainMenu:add_item{text="Move to a new Tag" , button1  = function()
    local t = createNewTag()
    module.client:tags({t})
    awful.tag.viewonly(t)
    mainMenu.visible = false
  end}

  itemLayer     = mainMenu:add_item({text="Layer"       , sub_menu=layerMenu(), button1 = function()  end})
  mainMenu:add_widget(radical.widgets.separator())

  local ib = wibox.widget.imagebox()
  ib:set_image(beautiful.titlebar_close_button_normal)
  itemClose      = mainMenu:add_item({text="Close",suffix_widget = ib, button1 = function() if module.client ~= nil then  module.client:kill();mainMenu.visible=false end end})

  return mainMenu
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
