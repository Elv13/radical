local setmetatable = setmetatable
--TODO rename to infoshape and infolayer, merge with constrainedtext, support icons
local util      = require( "awful.util"        )
local base      = require( "wibox.widget.base" )
local shape     = require( "gears.shape"       )
local beautiful = require( "beautiful"         )
local color     = require( "gears.color"       )
local cairo      = require("lgi").cairo
local pango      = require("lgi").Pango
local pangocairo = require("lgi").PangoCairo

local infoshape = { mt = {} }

local default_shape = shape.rounded_bar

-- local default_font_description = nil

local pango_l = {}

local padding = 2 --TODO do not hardcode

-- Cache the pango layout
local function init_pango(height)
    if pango_l[height] then return pango_l[height] end

    -- Get text height
    if not pango_l[height] then
        local pango_crx = pangocairo.font_map_get_default():create_context()
        pango_l[height] = pango.Layout.new(pango_crx)
        local desc = pango.FontDescription()
        desc:set_family("Verdana")
        desc:set_weight(pango.Weight.BOLD)
--         desc:set_size((height-padding*2) * pango.SCALE)
        desc:set_absolute_size((height - 2*padding) * pango.SCALE)
    --     desc:set_variant(pango.Variant.SMALL_CAPS)
        pango_l[height]:set_font_description(desc)

        return pango_l[height]
    end
end

local function get_extents(text, height)
    local l = init_pango(height)
    l.text = text or ""
    local _, ex = l:get_pixel_extents()
    return ex
end

local function get_group_extents(self, group, height)
    local ret = 0

    for k, v in ipairs(group) do
        ret = ret + get_extents(v.text, height).width + 2*height + (self._padding or 2) + (self.spacing or 0)
    end

    return ret
end

-- Add the shape to the context
local function draw_shape2(self, is, cr, width, height, ...)
    local s = is.shape or self._default_shape or default_shape

    if s then
        s(cr, width, height, ...)
    end
end

-- Draw a single buble
local function draw_shape(self, cr, width, height, infoshape)
    local text = infoshape.text

    -- Get the extents
    local extents = get_extents(text, height)
    local w,h = extents.width + 2*height, height - 2*padding

    -- Draw the shape
    draw_shape2(self, infoshape, cr, w, h) --TODO support padding, shape args

    -- The border
    local border_width = infoshape.border_width or self._shape_border_width or beautiful.infoshape_shape_border_width
    local border_color = infoshape.border_color or self._shape_border_color or beautiful.infoshape_shape_border_color
    if border_width and border_color then
        cr:set_source(color(border_color))
        cr:set_line_width(border_width)
        cr:stroke_preserve()
    end

    -- The background
    local bg = infoshape.bg or self.bg or beautiful.infoshape_shape_bg or beautiful.bg_focus
    cr:set_source(color(bg))

    -- The text
    local fg = infoshape.fg or self.fg or beautiful.infoshape_shape_fg-- or "#ff0000"

    local l = init_pango(height)

    if fg then
        cr:fill()
        cr:translate(height, extents.y - (height-extents.height)/2)
        cr:set_source(color(fg))
        cr:show_layout(l)
    else
        -- Allow the text to be transparent while the shape is solid
        --TODO find a better way to do this
        cr:clip()
        local img = cairo.ImageSurface(cairo.Format.ARGB32, w,h)
        local cr3 = cairo.Context(img)
        cr3:set_source_rgba(1,1,0,1)
        cr3:paint_with_alpha(infoshape.alpha or 1)
        cr3:translate(height, extents.y)
        cr3:layout_path(l)
        cr3:set_operator(cairo.Operator.CLEAR)
        cr3:fill()
        cr:mask_surface(img)
        cr:reset_clip()
        cr:translate(height, 0)
    end

    return extents.width + (border_width or 0), height
end

-- Draw a single section
local function draw_section_common(self, context, cr, width, height, section)
    cr:translate(0, padding)
    for k, v in ipairs(section) do
        local w = draw_shape(self, cr, width, height, v)
        cr:translate(w + (self._padding or 2) + height, 0)
    end
end

-- Compute the each section points [x,y] and paint them
local function draw_layer_common(self, context, cr, width, height, layer)
    if layer.left then
        cr:save()
        draw_section_common(self, context, cr, width, height, layer.left)
        cr:restore()
    end
    if layer.right then
        cr:save()
        cr:translate(width-get_group_extents(self, layer.right, height), 0)
        draw_section_common(self, context, cr, width, height, layer.right)
        cr:restore()
    end
    if layer.center then
        cr:save()
        local w = get_group_extents(self, layer.center, height)/2
        cr:translate(width/2-w, 0)
        draw_section_common(self, context, cr, width, height, layer.center)
        cr:restore()
    end
end

function infoshape:before_draw_children(context, cr, width, height)
    if self._below then
        draw_layer_common(self, context, cr, width, height, self._below)
    end
end

function infoshape:after_draw_children(context, cr, width, height)
    if self._above then
        draw_layer_common(self, context, cr, width, height, self._above)
    end
end

-- Support multiple align modes
function infoshape:layout(context, width, height)
    if self.widget then
        local w = self.widget:fit(context, width, height)
        if not self._align or self._align == "left" then --TODO use base.fit_widget
            return { base.place_widget_at(self.widget, 0, 0, w, height) }
        else
            if self._align == "center" then
                return { base.place_widget_at(self.widget, width/2-w/2, 0, w, height) }
            elseif self._align == "right" then
                return { base.place_widget_at(self.widget, width-w, 0, w, height) }
            end
        end
    end
end

-- The minimum fit is the same as the child widget, but extra space is welcome
function infoshape:fit(context, width, height)
    if not self.widget then
        return 0, 0
    end

    if self._expand_mode == "fill" then
        return width, height
    else
        return base.fit_widget(self, context, self.widget, width, height)
    end
end

function infoshape:set_widget(widget)
    if widget then
        base.check_widget(widget)
    end
    self.widget = widget
    self:emit_signal("widget::layout_changed")
end

function infoshape:get_children()
    return {self.widget}
end

function infoshape:set_children(children)
    self.widget = children and children[1]
    self:emit_signal("widget::layout_changed")
end

function infoshape:reset()
    self.direction = nil
    self:set_widget(nil)
end

--- Add a new info info shape.
--
-- Valid args are:
--
-- * align: "right" (default), "left" or "center"
-- * shape: A `gears.shape` compatible function (default: gears.shape.rounded_bar)
-- * layer: "below" (default) or "above"
-- * shape_border_width: The border width (default: 0)
-- * shape_border_color: The shape border color (default: none)
-- * font_description: A pango font description or string (default: Verdana bold)
-- * bg: The infoshape background color (default: beautiful.bg_infoshape or beautiful.bg_focus)
-- * fg: The text color (default: transparent)
-- * alpha: The infoshape alpha (transparency) a number between 0 and 1
--
-- @tparam string text The info text
-- @tparam[opt={}] table args the arguments
-- @treturn A unique identifier key
--
function infoshape:add_infoshape(args)
    args = args or {}
    local align = args.align or "right"
    local layer = args.layer or "below"
    if not self["_"..layer] then
        self["_"..layer] = {}
    end

    local l = self["_"..layer]

    if not l[align] then
        l[align] = {}
    end

    table.insert(l[align], args)

    self:emit_signal("widget::redraw_needed")
end

function infoshape:add_infoshapes(args)
    for k, v in ipairs(args or {}) do
        self:add_infoshape(v)
    end
end

--- Replace all infshapes with "args"
function infoshape:set_infoshapes(args)
    self._above = {}
    self._below = {}
    self:add_infoshapes(args)
    self:emit_signal("widget::redraw_needed")
end

--TODO fallback beautiful
function infoshape:set_shape(s)
    self._default_shape = s
end

--TODO fallback beautiful
function infoshape:set_shape_border_color(col)
    self._shape_border_color = col
end

--TODO fallback beautiful
function infoshape:set_shape_border_width(col)
    self._shape_border_width = col
end

-- function infoshape:set_default_font_description(desc)
--     default_font_description = desc
-- end

--TODO set default bg
--TODO set default fg


function infoshape:remove(key)
    
end

function infoshape:set_text(key, text)
    
end

function infoshape:set_spacing(spacing)
    
end

function infoshape:set_bg(col)
    
end

-- function infoshape:set_fg(col)
-- end

--- Set the expand mode.
-- Valid modes are:
--
-- * "fit": Take the same space as the child widget (default)
-- * "fill": Take all the available space
--
-- @tparams string mode The expand mode
function infoshape:set_expand(mode)
    self._expand_mode = mode
end

function infoshape:set_align(align)
    self._align = align
end


local function new(widget, dir)
    local ret = base.make_widget()

    util.table.crush(ret, infoshape)

    ret:set_widget(widget)

    return ret
end

function infoshape.mt:__call(...)
    return new(...)
end

return setmetatable(infoshape, infoshape.mt)

-- kate: space-indent on; indent-width 4; replace-tabs on;
