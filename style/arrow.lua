local setmetatable = setmetatable
local unpack       = unpack or table.unpack
local beautiful    = require( "beautiful"    )
local color        = require( "gears.color"  )
local base         = require( "radical.base" )
local shape        = require( "gears.shape"  )

local module = {
    margins = {
        BOTTOM = 10,
        TOP    = 10,
        LEFT   = 0 ,
        RIGHT  = 0 ,
    }
}

-- Matrix rotation per direction
local angles = {
    top    = math.pi     , -- 180
    bottom = 0           , -- 0
    left   = math.pi/2   , -- 90
    right  = 3*math.pi/2 , -- 270
}

-- If width and height need to be swapped
local swaps = {
    top   =  false,
    bottom=  false,
    right =  true ,
    left  =  true ,
}

local invert = {
    top    = "bottom",
    bottom = "top"   ,
    right  = "left"  , --FIXME this is wrong
    left   = "right" , --FIXME this is wrong
}

-- Constants
local radius       = 10
local arrow_height = 13

-- Generate the arrow position
local function gen_arrow_x(data, direction, width, height)
    local at = data.arrow_type

    local pg = data.parent_geometry

    if at == base.arrow_type.PRETTY or not at then
        if direction == "left" then
            --TODO
        elseif direction == "right" then
            data._internal.w:set_yoffset(-(20) + arrow_height)
        elseif direction == "bottom" then
            data._internal.w:set_xoffset(-(20) - arrow_height)
        elseif direction == "top" then
            data._internal.w:set_xoffset(-data._internal.w.width + (20) + arrow_height)
        end
    elseif at == base.arrow_type.CENTERED then
        if direction == "left" or direction == "right" then
            data._arrow_x = height/2 - arrow_height
            data._internal.w:set_yoffset(data._internal.w.height/2 - arrow_height)
        else
            data._arrow_x = width/2 - arrow_height
            if pg then
                data._internal.w:set_xoffset(-data._internal.w.width/2 + arrow_height + pg.width/2)
            else
                data._internal.w:set_xoffset(data._internal.w.width/2 - arrow_height)
            end
        end
    end
end

local function update_margins(data, pos)
    -- Set the margins correctly
    if data._internal.margin then
        data.margins.left   = module.margins.LEFT
        data.margins.right  = module.margins.RIGHT
        data.margins.top    = module.margins.TOP
        data.margins.bottom = module.margins.BOTTOM

        -- Add enough room for the arrow
        if pos and data.arrow_type ~= base.arrow_type.NONE then
            data.margins[invert[pos]] = data.margins[invert[pos]] + arrow_height
        end
    end
end

-- Generate a rounded cairo path with the arrow
local function draw_roundedrect_path(cr, width, height, rad, data, direction)
    direction = direction or "right"

    if data.arrow_type == base.arrow_type.NONE then
        if direction == "left" then
            data._internal.w:set_yoffset(-rad)
        elseif direction == "right" then
            data._internal.w:set_yoffset(rad)
        end
        return shape.rounded_rect(cr, width, height, rad)
    end

    local angle, swap = angles[direction], swaps[direction]

    -- Invert width and height to avoid distortion
    if swap then
        width, height = height, width
    end

    -- Use rounded rext for sub-menu and
    local s = shape.transform(shape.infobubble)

    -- Apply transformations
    s = s : rotate_at(width / 2, height / 2, angle)

    -- Decide where the arrow will be
    gen_arrow_x(data, data.direction, width, height)

    -- Forward to the real shape
    local ax = swap and width - (data._arrow_x or 20)-arrow_height - rad or (data._arrow_x or 20)
    s(cr, width, height, rad, arrow_height, ax)
end

local function draw(data)

    if not data._internal.arrow_setup then
        data._internal.w:set_shape_border_width(data.border_width or 1)
        data._internal.w:set_shape_border_color(color(beautiful.menu_outline_color or beautiful.menu_border_color or beautiful.fg_normal))
        data._internal.w:set_shape(data.shape or shape.infobubble, unpack(data.shape_args or {}))

        data._internal.w:connect_signal("property::direction", function(_, dir)
            data.direction = dir
            data._internal.w:set_shape(function(cr, w, h) draw_roundedrect_path(cr, w, h, data.radius or radius, data, dir) end)
            update_margins(data, dir)
        end)

--         local dir = data._internal.w.position
--         if dir then
--             data._internal.w:set_shape(function(cr, w, h) draw_roundedrect_path(cr, w, h, radius, data, data._internal.w.position) end)
--         end
        update_margins(data, nil)

        data._internal.arrow_setup = true
    end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
