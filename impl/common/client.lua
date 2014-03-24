local radical = require("radical")
local capi = { screen = screen, }
local awful     = require( "awful"      )
local module = {}

local function createTagList(aScreen)
  local tagList = radical.context({autodiscard = true})
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

return module--setmetatable(module, {})
-- kate: space-indent on; indent-width 2; replace-tabs on;