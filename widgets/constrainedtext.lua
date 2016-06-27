local color      = require( "gears.color" )
local pango      = require( "lgi"         ).Pango
local pangocairo = require( "lgi"         ).PangoCairo
local wibox      = require( "wibox"       )
local beautiful  = require( "beautiful"   )
local scale        = pango.SCALE

local function setup_dpi(box, dpi)
    if box._private.dpi ~= dpi then
        box._private.dpi = dpi
        box._private.ctx:set_resolution(dpi)
        box._private.layout:context_changed()
    end
end

--- Setup a pango layout for the given textbox and dpi
local function setup_layout(box, width, height, dpi)
--     box._private.layout.width  = pango.units_from_double(width) --FIXME...
    box._private.layout.height = pango.units_from_double(height)
    setup_dpi(box, dpi)
end

local function fit(self, context,width,height)

    setup_layout(self, width, height, context.dpi)

    -- Compute the optimal font size
    local padding   = self._private.padding or 0
    local tm        = self._private.top_margin or 0
    height          = math.max(0, height - tm)
    local min       = math.min(width, height)
    local font_size = math.max(0, min - 2*padding)

    if self._private.force_text then
        self._private.layout.text = self._private.force_text
    end

    self._private.desc:set_size( font_size * scale )
    self._private.layout:set_font_description(self._private.desc)

    local _, geo = self._private.layout:get_pixel_extents()

    if self._private.force_text then
        self._private.layout.text = self._private.text
    end

    return math.min(geo.width, width), math.min(geo.height + tm, height)
end

local function draw(self, context, cr, width, height)
    -- Some layouts never call fit()...
    fit(self, context, width, height)
    cr:update_layout(self._private.layout)

    local _, geo = self._private.layout:get_pixel_extents()
    local tm     = self._private.top_margin or 0
    local size   = math.min(width, height - tm)

    -- Translate the canvas to center the text
    local dy = ( size - geo.height  )/2 - geo.y + tm
    local dx = ( size - geo.width   )/2 - geo.x

    cr:move_to(0, dy)

    -- Show the text
    cr:show_layout(self._private.layout)
end

local function set_text(self, text)
    if tostring(text):len() == 1 then text = text.."_" end--FIXME...
    self._private.layout.text = text
    self._private.text = text
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

local function set_padding(self, padding)
    self._private.padding = padding
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

local function set_top_margin(self, margin)
    self._private.top_margin = margin or 0
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

local function set_width_for_text(self, text)
    self._private.force_text = text
    self:emit_signal("widget::redraw_needed")
    self:emit_signal("widget::layout_changed")
end

local function new(text, padding, top_margin)
    local wdg = wibox.widget.base.empty_widget()

    -- Add the basic functions
    rawset(wdg, "draw"              , draw               )
    rawset(wdg, "fit"               , fit                )
    rawset(wdg, "set_padding"       , set_padding        )
    rawset(wdg, "set_top_margin"    , set_top_margin     )
    rawset(wdg, "set_text"          , set_text           )
    rawset(wdg, "set_width_for_text", set_width_for_text )

    -- Create the pango objects
    local pango_crx = pangocairo.font_map_get_default():create_context()
    local pango_l   = pango.Layout.new(pango_crx)
    local desc      = pango.FontDescription()
    pango_l:set_alignment("CENTER")
    desc:set_family( "Verdana"         )
    desc:set_weight( pango.Weight.BOLD )

    wdg._private.layout = pango_l
    wdg._private.desc   = desc
    wdg._private.ctx   = pango_crx
    wdg:emit_signal("widget::layout_changed")

    if text       then set_text      (wdg, text      ) end
    if padding    then set_padding   (wdg, padding   ) end
    if top_margin then set_top_margin(wdg, top_margin) end

    return wdg
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
