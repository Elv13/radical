local type = type
local base      = require( "wibox.widget.base" )
local tooltip   = require( "radical.tooltip"   )
local underlay  = require( "radical.widgets.underlay")
local aw_button = require( "awful.button"      )
local beautiful = require( "beautiful"         )

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

local function _underlay_draw(self, context, cr, width, height)
  cr:save()
  local udl = underlay.draw(self._underlay,{height=height,style = self._underlay_style,bg=self._underlay_color})
  cr:set_source_surface(udl,width-udl:get_width()-3)
  cr:paint_with_alpha(self._underlay_alpha or beautiful.underlay_alpha or 0.7)
  cr:restore()
  self._draw_underlay(self, context, cr, width, height)
end

local function set_underlay(self,udl,args)
  local args = args or {}
  if not self._draw_underlay then
    self._draw_underlay = self.draw
    self.draw = _underlay_draw
  end
  self._underlay = udl
  self._underlay_style = args.style
  self._underlay_alpha = args.alpha
  self._underlay_color = args.color
  self:emit_signal("widget::updated")
end

-- Do some monkey patching to extend all wibox.widget
base._make_widget =base.make_widget
base.make_widget = function(...)
  local ret = base._make_widget(...)
  ret.set_tooltip  = set_tooltip
  ret.set_menu     = set_menu
  ret.set_underlay = set_underlay
  return ret
end

local bar = require( "radical.bar"     )

return {
  layout  = require( "radical.layout"  ),
  object  = require( "radical.object"  ),
  base    = require( "radical.base"    ),
  radial  = require( "radical.radial"  ),
  context = require( "radical.context" ),
  embed   = require( "radical.embed"   ),
  box     = require( "radical.box"     ),
  style   = require( "radical.style"   ),
  widgets = require( "radical.widgets" ),
  item    = require( "radical.item"    ),
  dock    = require( "radical.dock"    ),
  bar     = bar,
  flexbar = bar.flex,
  tooltip = tooltip
}
-- kate: space-indent on; indent-width 2; replace-tabs on;
