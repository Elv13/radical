local type = type
local base      = require( "wibox.widget.base" )
local tooltip   = require( "radical.tooltip"   )
local underlay  = require( "radical.widgets.underlay")
local aw_button = require( "awful.button"      )
local beautiful = require( "beautiful"         )

-- Define some wibox.widget extensions
local function set_tooltip(self, text, args)
  if not text then return end
  self._tooltip = tooltip(self,text, args)
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

    local dgeo = geo.drawable.drawable:geometry()
    -- The geometry is a mix of the drawable and widget one
    local geo2 = {
      x        = dgeo.x + geo.x,
      y        = dgeo.y + geo.y,
      width    = geo.width     ,
      height   = geo.height    ,
      drawable = geo.drawable  ,
    }

    m.parent_geometry = geo2
    m.visible = not m.visible
  end)
  for k, v in pairs(bt) do
    current[type(k) == "number" and (#current+1) or k] = v
  end
  self._menu = menu
  return bt
end

local function layer_draw_common(self, context, cr, width, height, typename)
  cr:save()

  local udl  = underlay.draw(self["_"..typename], {
      height = height,
      style  = self["_"..typename.."_style"],
      bg     = self["_"..typename.."_color"]
    },
    context
  )

  cr:set_source_surface(udl,width-udl:get_width()-3)
  cr:paint_with_alpha(self["_"..typename.."_alpha"] or beautiful[typename.."_alpha"] or 0.7)

  cr:restore()
end

local function draw_underlay(self, context, cr, width, height)
  layer_draw_common(self, context, cr, width, height, "underlay")

  if self._draw_original then
    self._draw_original(self, context, cr, width, height)
  end
end

local function draw_overlay(self, context, cr, width, height)
  if self._draw_original then
    self._draw_original(self, context, cr, width, height)
  end

  layer_draw_common(self, context, cr, width, height, "overlay")
end

local function set_layer_common(typename, self ,udl ,args)
  local args = args or {}

  if self.draw and not self._draw_original then
    self._draw_original = self.draw

    if typename == "underlay" then
      self.draw = draw_underlay
    elseif typename == "overlay" then
      self.draw = draw_overlay
    end

  elseif typename == "underlay" then
    self.before_draw_children = draw_underlay
  elseif typename == "overlay" then
    self.after_draw_children = draw_overlay
  end


  -- TODO detect if it is a Radical item and get those properties,
  -- then, delete item.layout implementations
  self["_"..typename          ] = udl
  self["_"..typename.."_style"] = args.style
  self["_"..typename.."_alpha"] = args.alpha
  self["_"..typename.."_color"] = args.color
  self:emit_signal("widget::updated")
end

local function set_underlay(...)
  set_layer_common("underlay",...)
end

local function set_overlay(...)
  set_layer_common("overlay",...)
end

local function get_preferred_size(self, context, width, height)
  local context = context or 1

  if type(context) == "number" then
    context = {dpi=beautiful.xresources.get_dpi(context)}
  elseif not context.dpi then
    context.dpi = beautiful.xresources.get_dpi(1)
  end

  return self:fit(context, width or 9999, height or 9999)
end

-- Do some monkey patching to extend all wibox.widget
base._make_widget =base.make_widget
base.make_widget = function(...)
  local ret = base._make_widget(...)
  ret.set_tooltip        = set_tooltip
  ret.set_menu           = set_menu
  ret.set_underlay       = set_underlay
  ret.set_overlay        = set_overlay

  -- Textboxes already have it
  if not ret.get_preferred_size then
    ret.get_preferred_size = get_preferred_size
  end

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
