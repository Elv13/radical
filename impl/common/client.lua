local radical = require("radical")
local type = type
local cairo     = require( "lgi"              ).cairo
local surface = require("gears.surface")
local shape = require("gears.shape")
local util = require("awful.util")
local module = {}

local sigMenu = nil
function module.signals()
  if sigMenu then
    return sigMenu
  end
  sigMenu = radical.context{max_items=10}
  sigMenu:add_item({text="SIGTERM"   , button1 = function() util.spawn("kill -s TERM    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="15"}}})
  sigMenu:add_item({text="SIGKILL"   , button1 = function() util.spawn("kill -s KILL    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="9"}}})
  sigMenu:add_item({text="SIGINT"    , button1 = function() util.spawn("kill -s INT     "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="2"}}})
  sigMenu:add_item({text="SIGQUIT"   , button1 = function() util.spawn("kill -s QUIT    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="3"}}})
--     sigMenu:add_widget(radical.widgets.separator())
  sigMenu:add_item({text="SIG0"      , button1 = function() util.spawn("kill -s 0       "..module.client.pid);sigMenu.visible = false end,infoshapes = {         }})
  sigMenu:add_item({text="SIGALRM"   , button1 = function() util.spawn("kill -s ALRM    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="14"}}})
  sigMenu:add_item({text="SIGHUP"    , button1 = function() util.spawn("kill -s HUP     "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="1"}},tooltip="sdfsdfsdf"})
  sigMenu:add_item({text="SIGPIPE"   , button1 = function() util.spawn("kill -s PIPE    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="13"}}})
  sigMenu:add_item({text="SIGPOLL"   , button1 = function() util.spawn("kill -s POLL    "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGPROF"   , button1 = function() util.spawn("kill -s PROF    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="27"}}})
  sigMenu:add_item({text="SIGUSR1"   , button1 = function() util.spawn("kill -s USR1    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="10"}}})
  sigMenu:add_item({text="SIGUSR2"   , button1 = function() util.spawn("kill -s USR2    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="12"}}})
  sigMenu:add_item({text="SIGVTALRM" , button1 = function() util.spawn("kill -s VTALRM  "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGSTKFLT" , button1 = function() util.spawn("kill -s STKFLT  "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGPWR"    , button1 = function() util.spawn("kill -s PWR     "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGWINCH"  , button1 = function() util.spawn("kill -s WINCH   "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGCHLD"   , button1 = function() util.spawn("kill -s CHLD    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="17"}}})
  sigMenu:add_item({text="SIGURG"    , button1 = function() util.spawn("kill -s URG     "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGTSTP"   , button1 = function() util.spawn("kill -s TSTP    "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGTTIN"   , button1 = function() util.spawn("kill -s TTIN    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="21"}}})
  sigMenu:add_item({text="SIGTTOU"   , button1 = function() util.spawn("kill -s TTOU    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="22"}}})
  sigMenu:add_item({text="SIGSTOP"   , button1 = function() util.spawn("kill -s STOP    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="17"}}})
  sigMenu:add_item({text="SIGCONT"   , button1 = function() util.spawn("kill -s CONT    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="18"}}})
  sigMenu:add_item({text="SIGABRT"   , button1 = function() util.spawn("kill -s ABRT    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="6"}}})
  sigMenu:add_item({text="SIGFPE"    , button1 = function() util.spawn("kill -s FPE     "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="8"}}})
  sigMenu:add_item({text="SIGILL"    , button1 = function() util.spawn("kill -s ILL     "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="4"}}})
  sigMenu:add_item({text="SIGSEGV"   , button1 = function() util.spawn("kill -s SEGV    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="11"}}})
  sigMenu:add_item({text="SIGTRAP"   , button1 = function() util.spawn("kill -s TRAP    "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="5"}}})
  sigMenu:add_item({text="SIGSYS"    , button1 = function() util.spawn("kill -s SYS     "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="12"}}})
  sigMenu:add_item({text="SIGEMT"    , button1 = function() util.spawn("kill -s EMT     "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGBUS"    , button1 = function() util.spawn("kill -s BUS     "..module.client.pid);sigMenu.visible = false end,infoshapes = {{text="7"}}})
  sigMenu:add_item({text="SIGXCPU"   , button1 = function() util.spawn("kill -s XCPU    "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  sigMenu:add_item({text="SIGXFSZ"   , button1 = function() util.spawn("kill -s XFSZ    "..module.client.pid);sigMenu.visible = false end,infoshapes = {}})
  return sigMenu
end

function module.screenshot(clients,geo)
  if not clients then return end

  local prev_menu= radical.context({layout=radical.layout.horizontal,item_layout=radical.item.layout.centerred,item_width=140,item_height=140,icon_size=100,
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

    -- Create a matrix to scale down the screenshot
    cr:scale(scale+0.05,scale+0.05)

    -- Paint the screenshot in the rounded rectangle
    cr:set_source_surface(surface(c.content))
    cr:paint()

    -- Create the item
    local prev_item = prev_menu:add_item({text = "<b>"..c.name.."</b>",icon=img})
    prev_menu.wibox.opacity=0.8
    prev_item.icon = surface.duplicate_surface(img, shape.rounded_rect, 10)
    prev_item.text  = "<b>"..c.name:gsub('&','&amp;').."</b>"

  end

  prev_menu.visible = true
  return prev_menu
end

return module--setmetatable(module, {})
-- kate: space-indent on; indent-width 2; replace-tabs on;
