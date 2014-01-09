local type = type
local base      = require( "wibox.widget.base" )
local tooltip   = require( "radical.tooltip"   )
local aw_button = require( "awful.button"      )

-- Define some wibox.widget extensions
local function set_tooltip(self, text)
  if not text then return end
  self._tooltip = tooltip(self,text)
end

local function set_menu(self,menu,button)
  if not menu then return end
  local b = button or 1
  local current,bt = self:buttons(),aw_button({},b,function(geo)
    local m =  menu
    if type(menu) == "function" then
      if self._tmp_menu and self._tmp_menu.visible then
        self._tmp_menu.visible = false
        self._tmp_menu = nil
        return
      end
      m = menu(self)
    end
    if not m then return end
    m.parent_geometry = geo
    m.visible = not m.visible
  end)
  for k, v in pairs(bt) do
    current[type(k) == "number" and (#current+1) or k] = v
  end
  self._menu = menu
  return bt
end

-- Do some monkey patching to extend all wibox.widget
base._make_widget =base.make_widget
base.make_widget = function(...)
  local ret = base._make_widget(...)
  ret.set_tooltip = set_tooltip
  ret.set_menu    = set_menu
  return ret
end

return {
  layout     = require( "radical.layout"     ),
  object     = require( "radical.object"     ),
  base       = require( "radical.base"       ),
  radial     = require( "radical.radial"     ),
  context    = require( "radical.context"    ),
  embed      = require( "radical.embed"      ),
  box        = require( "radical.box"        ),
  bar        = require( "radical.bar"        ),
  style      = require( "radical.style"      ),
  item_style = require( "radical.item_style" ),
  widgets    = require( "radical.widgets"    ),
  tooltip    = tooltip
}
-- kate: space-indent on; indent-width 2; replace-tabs on;
