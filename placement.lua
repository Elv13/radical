local capi   = {screen=screen, mouse = mouse}
local unpack = unpack or table.unpack
local mouse  = require( "awful.mouse"  )
local screen = require( "awful.screen" )
local cairo  = require( "lgi"          ).cairo

local module = {}

-- Compute the new `x` and `y`.
-- The workarea position need to be applied by the caller
local map = {
    -- Corners
    top_left     = function(sw, sh, dw, dh) return {x=0        , y=0        } end,
    top_right    = function(sw, sh, dw, dh) return {x=sw-dw    , y=0        } end,
    bottom_left  = function(sw, sh, dw, dh) return {x=0        , y=sh-dh    } end,
    bottom_right = function(sw, sh, dw, dh) return {x=sw-dw    , y=sh-dh    } end,
    left         = function(sw, sh, dw, dh) return {x=0        , y=sh/2-dh/2} end,
    right        = function(sw, sh, dw, dh) return {x=sw-dw    , y=sh/2-dh/2} end,
    top          = function(sw, sh, dw, dh) return {x=sw/2-dw/2, y=0        } end,
    bottom       = function(sw, sh, dw, dh) return {x=sw/2-dw/2, y=sh-dh    } end,
}

-- Create the geometry rectangle 1=best case, 2=fallback
local positions = {
    left1   = function(x, y, w, h) return {x = x - w, y = y     , width = w, height = h} end,
    left2   = function(x, y, w, h) return {x = x - w, y = y - h , width = w, height = h} end,
    right1  = function(x, y, w, h) return {x = x    , y = y     , width = w, height = h} end,
    right2  = function(x, y, w, h) return {x = x    , y = y - h , width = w, height = h} end,
    top1    = function(x, y, w, h) return {x = x    , y = y - h , width = w, height = h} end,
    top2    = function(x, y, w, h) return {x = x - w, y = y - h , width = w, height = h} end,
    bottom1 = function(x, y, w, h) return {x = x    , y = y     , width = w, height = h} end,
    bottom2 = function(x, y, w, h) return {x = x - w, y = y     , width = w, height = h} end,
}

-- Check if the proposed geometry fit in the screen
local function fit_in_screen(s, geo)
    local sgeo = capi.screen[s].geometry
    local region = cairo.Region.create_rectangle(cairo.RectangleInt(sgeo))

    region:intersect(cairo.Region.create_rectangle(
        cairo.RectangleInt(geo)
    ))

    local geo2 = region:get_rectangle(0)

    -- If the geometry is the same, then it fit, else, it will be cropped
    --TODO in case all directions are cropped, keep the least cropped one
    return geo2.width == geo.width and geo2.height == geo.height
end

--- Move the drawable (client or wibox) `d` to a screen corner or side.
function module.corner(d, corner, s, honor_wa, update_wa)
    local sgeo = capi.screen[s][honor_wa and "workarea" or "geometry"]
    local dgeo = d:geometry()

    local pos = map[corner](sgeo.width, sgeo.height, dgeo.width, dgeo.height)

    d : geometry {
        x      = math.ceil(sgeo.x + pos.x) ,
        y      = math.ceil(sgeo.y + pos.y) ,
        width  = math.ceil(dgeo.width    ) ,
        height = math.ceil(dgeo.height   ) ,
    }

    --TODO update_wa
end

--- Pin a drawable to a placement function.
-- Auto update the position when the size change
function module.pin(d, f, ...)
    --TODO memory leak

    local args = {...}

    local function tracker()
        f(d, unpack(args))
    end

    d:connect_signal("property::width" , tracker)
    d:connect_signal("property::height", tracker)

    tracker()
end

--- Get the possible 2D anchor points around a widget geometry.
-- This take into account the widget drawable (wibox) and try to avoid
-- overlapping.
function module.get_relative_points(geo, mode)
    local use_mouse = true --TODO support modes

    -- The closest points around the geometry
    local dps = {}

    -- Use the mouse position and the wibox/client under it
    if not geo then
        local draw   = mouse.drawin_under_pointer()
        geo          = draw and draw:geometry() or capi.mouse.coords()
        geo.drawable = draw
    elseif geo.x and geo.width then
        local coords = capi.mouse.coords()

        -- Check id the mouse is in the rect
        if coords.x > geo.x and coords.x < geo.x+geo.width and
           coords.y > geo.y and coords.y < geo.y+geo.height then
            geo.drawable = mouse.drawin_under_pointer()
        end
        --TODO add drawin_at(x,y) in the C core
    end

    if geo.drawable then
        -- Case 1: A widget

        local dgeo = geo.drawable.drawable:geometry()

        -- Compute the absolute widget geometry
        local abs_widget_geo = {
            x        = dgeo.x + geo.x,
            y        = dgeo.y + geo.y,
            width    = geo.width     ,
            height   = geo.height    ,
            drawable = geo.drawable  ,
        }

        -- Get the comparaison point
        local center_point = use_mouse and capi.mouse.coords() or {
            x = abs_widget_geo.x + abs_widget_geo.width  / 2,
            y = abs_widget_geo.y + abs_widget_geo.height / 2,
        }

        -- Get the 4 cloest points from `center_point` around the wibox
        local points = {
            left   = {x = dgeo.x              , y = center_point.y       },
            right  = {x = dgeo.x + dgeo.width , y = center_point.y       },
            top    = {x = center_point.x      , y = dgeo.y               },
            bottom = {x = center_point.x      , y = dgeo.y + dgeo.height },
        }

        local s = geo.drawable.screen or screen.getbycoord(
                                            center_point.x,
                                            center_point.y
                                         )

        -- Compute the distance (dp) between the `center_point` and the sides
        for k, v in pairs(points) do
            local dx, dy = v.x - center_point.x, v.y - center_point.y
            dps[k] = {
                distance = math.sqrt(dx*dx + dy*dy),
                x        = v.x,
                y        = v.y,
                screen   = s
            }
        end

    else
        -- Case 2: A random geometry
        --TODO
    end

    return dps
end

-- @tparam drawable d A wibox or client
-- @tparam table points A table with position as key and points (x,y) as value
-- @tparam[opt={}] table preferred_positions The preferred positions (position as key,
--  and index as value)
-- @treturn string The choosen position
function module.move_relative(d, points, preferred_positions)
    local w,h = d.width, d.height

    local pref_idx, pref_name = 99, nil

    local does_fit = {}
    for k,v in pairs(points) do
        local geo = positions[k..1](v.x, v.y, w, h)
        local fit = fit_in_screen(v.screen, geo)

        -- Try the other compatible geometry
        if not fit then
            geo = positions[k..2](v.x, v.y, w, h)
            fit = fit_in_screen(v.screen, geo)
        end

        does_fit[k] = fit and geo or nil

        if fit and preferred_positions[k] and preferred_positions[k] < pref_idx then
            pref_idx  = preferred_positions[k]
            pref_name = k
        end

        -- No need to continue
        if fit and preferred_positions[k] == 1 then break end
    end

    local pos_name = pref_name or next(does_fit)
    local pos      = does_fit[pos_name]

    if pos then
        d.x = math.ceil(pos.x)
        d.y = math.ceil(pos.y)
    end

    return pos_name
end

return module
