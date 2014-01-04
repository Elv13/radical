local base    = require( "wibox.widget.base" )
local tooltip = require( "radical.tooltip"   )

-- Define some wibox.widget extensions
local function set_tooltip(self, text)
  print("HERE",text)
  if not text then return end
  self._tooltip = tooltip(self,text)
end

-- Do some monkey patching to extend all wibox.widget
base._make_widget =base.make_widget
base.make_widget = function(...)
  local ret = base._make_widget(...)
  ret.set_tooltip = set_tooltip
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
