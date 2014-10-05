local radical = require("radical")
local capi = { screen = screen, }
local type,math = type,math
local awful     = require( "awful"      )
local cairo     = require( "lgi"              ).cairo
local surface = require("gears.surface")
local module = {}

local function createTagList(aScreen)
  local tagList = radical.context {}
  for _, v in ipairs(awful.tag.gettags(aScreen)) do
    tagList:add_item({text = v.name,icon=awful.tag.geticon(v)})
  end
  return tagList
end

local sigMenu = nil
function module.signals()
  if sigMenu then
    return sigMenu
  end
  sigMenu       = radical.context{max_items=10}
  sigterm       = sigMenu:add_item({text="SIGTERM"   , button1 = function() util.spawn("kill -s TERM    "..module.client.pid);mainMenu.visible = false end,underlay="15"})
  sigkill       = sigMenu:add_item({text="SIGKILL"   , button1 = function() util.spawn("kill -s KILL    "..module.client.pid);mainMenu.visible = false end,underlay="9"})
  sigint        = sigMenu:add_item({text="SIGINT"    , button1 = function() util.spawn("kill -s INT     "..module.client.pid);mainMenu.visible = false end,underlay="2"})
  sigquit       = sigMenu:add_item({text="SIGQUIT"   , button1 = function() util.spawn("kill -s QUIT    "..module.client.pid);mainMenu.visible = false end,underlay="3"})
--     sigMenu:add_widget(radical.widgets.separator())
  sig0          = sigMenu:add_item({text="SIG0"      , button1 = function() util.spawn("kill -s 0       "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigalrm       = sigMenu:add_item({text="SIGALRM"   , button1 = function() util.spawn("kill -s ALRM    "..module.client.pid);mainMenu.visible = false end,underlay="14"})
  sighup        = sigMenu:add_item({text="SIGHUP"    , button1 = function() util.spawn("kill -s HUP     "..module.client.pid);mainMenu.visible = false end,underlay="1",tooltip="sdfsdfsdf"})
  sigpipe       = sigMenu:add_item({text="SIGPIPE"   , button1 = function() util.spawn("kill -s PIPE    "..module.client.pid);mainMenu.visible = false end,underlay="13"})
  sigpoll       = sigMenu:add_item({text="SIGPOLL"   , button1 = function() util.spawn("kill -s POLL    "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigprof       = sigMenu:add_item({text="SIGPROF"   , button1 = function() util.spawn("kill -s PROF    "..module.client.pid);mainMenu.visible = false end,underlay="27"})
  sigusr1       = sigMenu:add_item({text="SIGUSR1"   , button1 = function() util.spawn("kill -s USR1    "..module.client.pid);mainMenu.visible = false end,underlay="10"})
  sigusr2       = sigMenu:add_item({text="SIGUSR2"   , button1 = function() util.spawn("kill -s USR2    "..module.client.pid);mainMenu.visible = false end,underlay="12"})
  sigsigvtalrm  = sigMenu:add_item({text="SIGVTALRM" , button1 = function() util.spawn("kill -s VTALRM  "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigstkflt     = sigMenu:add_item({text="SIGSTKFLT" , button1 = function() util.spawn("kill -s STKFLT  "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigpwr        = sigMenu:add_item({text="SIGPWR"    , button1 = function() util.spawn("kill -s PWR     "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigwinch      = sigMenu:add_item({text="SIGWINCH"  , button1 = function() util.spawn("kill -s WINCH   "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigchld       = sigMenu:add_item({text="SIGCHLD"   , button1 = function() util.spawn("kill -s CHLD    "..module.client.pid);mainMenu.visible = false end,underlay="17"})
  sigurg        = sigMenu:add_item({text="SIGURG"    , button1 = function() util.spawn("kill -s URG     "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigtstp       = sigMenu:add_item({text="SIGTSTP"   , button1 = function() util.spawn("kill -s TSTP    "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigttin       = sigMenu:add_item({text="SIGTTIN"   , button1 = function() util.spawn("kill -s TTIN    "..module.client.pid);mainMenu.visible = false end,underlay="21"})
  sigttou       = sigMenu:add_item({text="SIGTTOU"   , button1 = function() util.spawn("kill -s TTOU    "..module.client.pid);mainMenu.visible = false end,underlay="22"})
  sigstop       = sigMenu:add_item({text="SIGSTOP"   , button1 = function() util.spawn("kill -s STOP    "..module.client.pid);mainMenu.visible = false end,underlay="17"})
  sigcont       = sigMenu:add_item({text="SIGCONT"   , button1 = function() util.spawn("kill -s CONT    "..module.client.pid);mainMenu.visible = false end,underlay="18"})
  sigabrt       = sigMenu:add_item({text="SIGABRT"   , button1 = function() util.spawn("kill -s ABRT    "..module.client.pid);mainMenu.visible = false end,underlay="6"})
  sigfpe        = sigMenu:add_item({text="SIGFPE"    , button1 = function() util.spawn("kill -s FPE     "..module.client.pid);mainMenu.visible = false end,underlay="8"})
  sigill        = sigMenu:add_item({text="SIGILL"    , button1 = function() util.spawn("kill -s ILL     "..module.client.pid);mainMenu.visible = false end,underlay="4"})
  sigsegv       = sigMenu:add_item({text="SIGSEGV"   , button1 = function() util.spawn("kill -s SEGV    "..module.client.pid);mainMenu.visible = false end,underlay="11"})
  sigtrap       = sigMenu:add_item({text="SIGTRAP"   , button1 = function() util.spawn("kill -s TRAP    "..module.client.pid);mainMenu.visible = false end,underlay="5"})
  sigsys        = sigMenu:add_item({text="SIGSYS"    , button1 = function() util.spawn("kill -s SYS     "..module.client.pid);mainMenu.visible = false end,underlay="12"})
  sigemt        = sigMenu:add_item({text="SIGEMT"    , button1 = function() util.spawn("kill -s EMT     "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigbus        = sigMenu:add_item({text="SIGBUS"    , button1 = function() util.spawn("kill -s BUS     "..module.client.pid);mainMenu.visible = false end,underlay="7"})
  sigxcpu       = sigMenu:add_item({text="SIGXCPU"   , button1 = function() util.spawn("kill -s XCPU    "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  sigxfsz       = sigMenu:add_item({text="SIGXFSZ"   , button1 = function() util.spawn("kill -s XFSZ    "..module.client.pid);mainMenu.visible = false end,underlay=nil})
  return sigMenu
end

function module.screenshot(clients,geo)
  if not clients then return end

  local prev_menu= radical.context({layout=radical.layout.horizontal,item_width=140,item_height=140,icon_size=100,
      arrow_type=radical.base.arrow_type.CENTERED,enable_keyboard=false,item_style=radical.item.style.rounded})
  local t = type(clients)
  if t == "client" then
    clients = {clients}
  elseif t == "tag" then
    clients = clients:clients()
  end

  --TODO detect black

  for k,c in ipairs(clients) do
    local geom = c:geometry()
    local ratio,h_or_w = geom.width/geom.height,geom.width>geom.height
    local w,h,scale = h_or_w and 140 or (140*ratio),h_or_w and (140*ratio) or 140,h_or_w and 140/geom.width or 140/geom.height


    -- Create a working surface
    local img = cairo.ImageSurface(cairo.Format.ARGB32, w, h)
    local cr = cairo.Context(img)

    -- Create a mask
    cr:arc(10,10,10,0,math.pi*2)
    cr:fill()
    cr:arc(w-10,10,10,0,math.pi*2)
    cr:fill()
    cr:arc(w-10,h-10,10,0,math.pi*2)
    cr:fill()
    cr:arc(10,h-10,10,0,math.pi*2)
    cr:fill()
    cr:rectangle(10,0,w-20,h)
    cr:rectangle(0,10,w,h-20)
    cr:fill()

    -- Create a matrix to scale down the screenshot
    cr:scale(scale+0.05,scale+0.05)

    -- Paint the screenshot in the rounded rectangle
    cr:set_source_surface(surface(c.content))
    cr:set_operator(cairo.Operator.IN)
    cr:paint()

    -- Create the item
    local prev_item = prev_menu:add_item({text = "<b>"..c.name.."</b>",icon=img})
    prev_menu.wibox.opacity=0.8
    prev_item.icon = img
    prev_item.text  = "<b>"..c.name:gsub('&','&amp;').."</b>"

  end

  if geo then
    prev_menu.parent_geometry = geo
  end

  prev_menu.visible = true
  return prev_menu
end

return module--setmetatable(module, {})
-- kate: space-indent on; indent-width 2; replace-tabs on;