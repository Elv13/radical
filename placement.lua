local capi   = {screen=screen, mouse = mouse}
local unpack = unpack or table.unpack
local mouse  = require( "awful.mouse"  )
local screen = require( "awful.screen" )
local tag    = require( "awful.tag"    ) --TODO do the opposite, include placement in awful.tag
local cairo  = require( "lgi"          ).cairo

local module = {}

-- Compute the new `x` and `y`.
-- The workarea position need to be applied by the caller
local map = {
    top_left          = function(sw, sh, dw, dh) return {x=0        , y=0        } end,
    top_right         = function(sw, sh, dw, dh) return {x=sw-dw    , y=0        } end,
    bottom_left       = function(sw, sh, dw, dh) return {x=0        , y=sh-dh    } end,
    bottom_right      = function(sw, sh, dw, dh) return {x=sw-dw    , y=sh-dh    } end,
    left              = function(sw, sh, dw, dh) return {x=0        , y=sh/2-dh/2} end,
    right             = function(sw, sh, dw, dh) return {x=sw-dw    , y=sh/2-dh/2} end,
    top               = function(sw, sh, dw, dh) return {x=sw/2-dw/2, y=0        } end,
    bottom            = function(sw, sh, dw, dh) return {x=sw/2-dw/2, y=sh-dh    } end,
    centered          = function(sw, sh, dw, dh) return {x=sw/2-dw/2, y=sh/2-dh/2} end,
    center_vertical   = function(sw, sh, dw, dh) return {x= nil     , y=sh-dh    } end,
    center_horizontal = function(sw, sh, dw, dh) return {x=sw/2-dw/2, y= nil     } end,
}

-- Store function -> keys
local reverse_map = {}

-- Create the geometry rectangle 1=best case, 2=fallback
local positions = {
    left1   = function(r, w, h) return {x=r.x-w        , y=r.y            }, "down"  end,
    left2   = function(r, w, h) return {x=r.x-w        , y=r.y-h+r.height }, "up"    end,
    right1  = function(r, w, h) return {x=r.x          , y=r.y            }, "down"  end,
    right2  = function(r, w, h) return {x=r.x          , y=r.y-h+r.height }, "up"    end,
    top1    = function(r, w, h) return {x=r.x          , y=r.y-h          }, "right" end,
    top2    = function(r, w, h) return {x=r.x-w+r.width, y=r.y-h          }, "left"  end,
    bottom1 = function(r, w, h) return {x=r.x          , y=r.y            }, "right" end,
    bottom2 = function(r, w, h) return {x=r.x-w+r.width, y=r.y            }, "left"  end,
}

-- Check if the proposed geometry fit in the screen
local function fit_in_screen(s, geo) --TODO replace by fit_in_bounding
    local sgeo   = capi.screen[s].geometry
    local region = cairo.Region.create_rectangle(cairo.RectangleInt(sgeo))

    region:intersect(cairo.Region.create_rectangle(
        cairo.RectangleInt(geo)
    ))

    local geo2 = region:get_rectangle(0)

    -- If the geometry is the same, then it fit, else, it will be cropped
    --TODO in case all directions are cropped, keep the least cropped one
    return geo2.width == geo.width and geo2.height == geo.height
end

local function apply_geometry_ajustments(geo, delta)
    return {
        x      = geo.x + (delta.left or 0),
        y      = geo.y + (delta.top  or 0),
        width  = geo.width  - (delta.left or 0) - (delta.right  or 0),
        height = geo.height - (delta.top  or 0) - (delta.bottom or 0),
    }
end

--- Get a placement bounding geometry.
-- This method offer a flexible way to build a customized outer geometry used
-- by the various functions of this module.
--
-- Valid arguments are:
--
-- * honor_padding
-- * honor_workarea
-- * margins
-- * tag
-- * parent: A parent drawable to use a base geometry
-- * bounding_rect: A bounding rectangle
--
-- @tparam[opt=mouse.screen] screen s A screen
-- @tparam[opt={}] table args The arguments
function module.get_bounding_geometry(s, args)
    args = args or {}

    -- If the tag has a geometry, assume it is right
    if args.tag then
        local geo = tag.getproperty(args.tag, "geometry")
        if geo then
            return geo
        end
    end

    s = s or capi.mouse.screen

    local geo = args.bounding_rect or (args.parent and parent:geometry()) or
        capi.screen[s][args.honor_workarea and "workarea" or "geometry"]

    if (not args.parent) and (not args.bounding_rect) and args.honor_padding then
        local padding = screen.padding(s) or {}
        geo = apply_geometry_ajustments(geo, padding)
    end

    if args.margins then
        geo = apply_geometry_ajustments(geo,
            type(args.margins) == "table" and args.margins or {
                left = args.margins, right  = args.margins,
                top  = args.margins, bottom = args.margins,
            }
        )
    end

    return geo
end

--- Move the drawable (client or wibox) `d` to a screen position or side.
--
-- Supported positions are:
--
-- * top_left
-- * top_right
-- * bottom_left
-- * bottom_right
-- * left
-- * right
-- * top
-- * bottom
-- * centered
-- * center_vertical
-- * center_horizontal
--
-- The valid other arguments are:
--
-- * *honor_workarea*: Take workarea into account when placing the drawable (default: false)
-- * *honor_padding*: Take the screen padding into account (see `awful.screen.padding`)
-- * *tag*: Use a tag geometry
-- * *margins*: A table with left, right, top, bottom keys or a number
-- * *parent*: A parent drawable to use a base geometry
-- * *bounding_rect*: A bounding rectangle
--
-- @tparam drawable d A drawable (like `client` or `wibox`)
-- @tparam string position One of the position mentionned above
-- @param[opt=d.screen or capi.mouse.screen] parent The parent geometry
-- @tparam[opt={}] table args Other arguments
function module.align(d, position, parent, args)
    d = d or capi.client.focus
    if not d then return end

    args   = args or {}
    parent = parent or d.screen or capi.mouse.screen


    -- Get the parent geometry
    local parent_type = type(parent)

    local sgeo = (parent_type == "screen" or parent_type == "number") and
        module.get_bounding_geometry(parent, args) or parent:geometry()

    local dgeo = d:geometry()

    local pos = map[position](sgeo.width, sgeo.height, dgeo.width, dgeo.height)

    d : geometry {
        x      = pos.x and math.ceil(sgeo.x + pos.x) or dgeo.x,
        y      = pos.y and math.ceil(sgeo.y + pos.y) or dgeo.y,
        width  =           math.ceil(dgeo.width    )          ,
        height =           math.ceil(dgeo.height   )          ,
    }
end

-- Add the alias functions
for k,v in pairs(map) do
    module[k] = function(d, p, args)
        module.align(d, k, p, args)
    end

    reverse_map[module[k]] = k
end

--- Stretch a drawable in a specific direction.
-- Valid args:
--
-- * *preserve_ratio*: 
-- * *margins*: A margin value or table
-- * *honor_workarea*:
-- * *honor_padding*:
-- * *tag*: Use a tag geometry, this honor the workarea, padding and gaps
-- * *parent*: A parent drawable to use a base geometry
-- * *bounding_rect*: A bounding rectangle
-- * minimim_height:
-- * minimim_width:
--
-- @tparam[opt=client.focus] drawable d A drawable (like `client` or `wibox`)
-- @tparam string direction The stretch direction (left, right, up, down)
-- @tparam[opt={}] table args The arguments
function module.stretch(d, direction, args)
    d = d or capi.client.focus
    if not d then return end

    --TODO maybe this could be integrated with the resize matrix?
    local sgeo = module.get_bounding_geometry(d.screen, args)
    local dgeo = d:geometry()
    local ngeo = dgeo

    if direction == "left" then
        ngeo.x      = sgeo.x
        ngeo.width  = (sgeo.width - sgeo.x) - (ngeo.x + ngeo.width)
    elseif direction == "right" then
        ngeo.width  = sgeo.width - ngeo.x
    elseif direction == "up" then
        ngeo.y      = sgeo.y
        ngeo.height = (sgeo.height - sgeo.y) - (ngeo.y + ngeo.height)
    elseif direction == "down" then
        ngeo.height = sgeo.height - dgeo.y
    end

    -- Avoid negative sizes
    ngeo.width  = math.max(args.minimim_width  or 1, ngeo.width )
    ngeo.height = math.max(args.minimim_height or 1, ngeo.height)
end

-- Add the alias functions
for k,v in ipairs {"left", "right", "up", "down"} do
    module["stretch_"..v] =  function(d, args) module.stretch(d, v, args) end
end

--- Maximize a drawable horizontally, vertically or both.
-- Valid args:
--
-- * *preserve_ratio*: 
-- * *margins*: A margin value or table
-- * *honor_workarea*:
-- * *honor_padding*:
-- * *tag*: Use a tag geometry, this honor the workarea, padding and gaps
-- * *parent*: A parent drawable to use a base geometry
-- * *bounding_rect*: A bounding rectangle
--
-- @tparam[opt=client.focus] drawable d A drawable (like `client` or `wibox`)
-- @tparam string axis The  axis (vertically or horizontally)
-- @tparam[opt={}] table args The arguments
function module.maximize(d, axis, args)
    d = d or capi.client.focus
    if not d then return end

    local sgeo = module.get_bounding_geometry(d.screen, args)
    local dgeo = d:geometry()
    local ngeo = dgeo

    if (not axis) or axis:match("vertical") then
        ngeo.y      = sgeo.y
        ngeo.height = sgeo.height
    end

    if (not axis) or axis:match("horizontal") then
        ngeo.x      = sgeo.x
        ngeo.width  = sgeo.width
    end

    d:geometry(ngeo)
end

-- Add the alias functions
for k, v in ipairs {"vertically", "horizontally"} do
    module["maximize_"..v] = function(d, args) module.maximize(d, v, args) end
end

--- Pin a drawable to a placement function.
-- Automatically update the position when the size change.
-- All other arguments will be passed to the `position` function (if any)
-- @tparam[opt=client.focus] drawable d A drawable (like `client` or `wibox`)
-- @param position A position name (see `align`) or a position function
function module.attach(d, position, ...)
    d = d or capi.client.focus
    if not d then return end

    if type(position) == "string" then
        position = module[position]
    end

    if not position then return end

    local args = {...}

    local function tracker()
        position(d, unpack(args))
    end

    d:connect_signal("property::width" , tracker)
    d:connect_signal("property::height", tracker)

    tracker()
end

-- Update the workarea
local function wibox_update_strut(d, position)
    -- If the drawable isn't visible, remove the struts
    if not d.visible then
        d:struts { left = 0, right = 0, bottom = 0, top = 0 }
        return
    end

    -- Detect horizontal or vertical drawables
    local geo      = d:geometry()
    local vertical = geo.width < geo.height

    -- Look into the `position` string to find the relevants sides to crop from
    -- the workarea
    local struts = { left = 0, right = 0, bottom = 0, top = 0 }

    if vertical then
        for k, v in ipairs {"right", "left"} do
            if (not position) or position:match(v) then
                struts[v] = geo.width + 2 * d.border_width
            end
        end
    else
        for k, v in ipairs {"top", "bottom"} do
            if (not position) or position:match(v) then
                struts[v] = geo.height + 2 * d.border_width
            end
        end
    end

    -- Update the workarea
    d:struts(struts)
end

function module.attach_struts(d, f, ...)
    module.attach(d, f, ...)
    --TODO if there is multiple attach_struts, update them, see `raise_attached_struts`

    local function tracker()
        wibox_update_strut(d, reverse_map[f])
    end

    d:connect_signal("property::geometry" , tracker)
    d:connect_signal("property::visible"  , tracker)

    tracker()
end

--- Move a drawable to the "top priority" of attached_structs
function module.raise_attached_struts()
    
end

-- Create a pair of rectangles used to set the relative areas.
-- v=vertical, h=horizontal
local function get_cross_sections(abs_geo, mode)
    if not mode or mode == "cursor" then
        -- A 1px cross section centered around the mouse position

        local coords = capi.mouse.coords()
        return {
            h = {
                x      = abs_geo.drawable_geo.x     ,
                y      = coords.y                   ,
                width  = abs_geo.drawable_geo.width ,
                height = 1                          ,
            },
            v = {
                x      = coords.x                   ,
                y      = abs_geo.drawable_geo.y     ,
                width  = 1                          ,
                height = abs_geo.drawable_geo.height,
            }
        }
    elseif mode == "widget" then
        -- The widget geometry extended to reach the end of the drawable

        return {
            h = {
                x      = abs_geo.drawable_geo.x     ,
                y      = abs_geo.y                  ,
                width  = abs_geo.drawable_geo.width ,
                height = abs_geo.height             ,
            },
            v = {
                x      = abs_geo.x                  ,
                y      = abs_geo.drawable_geo.y     ,
                width  = abs_geo.width              ,
                height = abs_geo.drawable_geo.height,
            }
        }
    elseif mode == "cursor_inside" then
        -- A 1x1 rectangle  centered around the mouse position

        local coords = capi.mouse.coords()
        coords.width,coords.height = 1,1
        return {h=coords, v=coords}
    elseif mode == "widget_inside" then
        -- The widget absolute geometry, unchanged

        return {h=abs_geo, v=abs_geo}
    end

    assert(false)
end

--- Get the possible 2D anchor points around a widget geometry.
-- This take into account the widget drawable (wibox) and try to avoid
-- overlapping.
--
-- Valid arguments are:
--
-- * xoffset
-- * yoffset
-- * margins: A table with "left", "right", "top" and "bottom" as key or a number
--
-- @tparam table geo A geometry table with optional "drawable" member
-- @tparam[opt="widget"] string mode TODO document
-- @tparam[opt={}] table args
function module.get_relative_points(geo, mode, args) --TODO rename regions
    mode = mode or "widget"
    args = args or {}

    -- Use the mouse position and the wibox/client under it
    if not geo then
        local draw   = mouse.drawin_under_pointer()
        geo          = draw and draw:geometry() or capi.mouse.coords()
        geo.drawable = draw
    elseif (not geo.drawable) and geo.x and geo.width then
        local coords = capi.mouse.coords()

        -- Check id the mouse is in the rect
        if coords.x > geo.x and coords.x < geo.x+geo.width and
          coords.y > geo.y and coords.y < geo.y+geo.height then
            geo.drawable = mouse.drawin_under_pointer()
        end
    end

    -- Get the drawable geometry
    local dpos = geo.drawable and geo.drawable.drawable:geometry() or {x=0, y=0}

    -- Compute the absolute widget geometry
    local abs_widget_geo = {
        x            = dpos.x + geo.x              ,
        y            = dpos.y + geo.y              ,
        width        = geo.width                   ,
        height       = geo.height                  ,
        drawable     = geo.drawable                ,
        drawable_geo = geo.drawable and dpos or geo,
    }

    -- Get the comparaison point
    local center_point = mode:match("cursor") and capi.mouse.coords() or {
        x = abs_widget_geo.x + abs_widget_geo.width  / 2,
        y = abs_widget_geo.y + abs_widget_geo.height / 2,
    }

    -- Get widget regions for both axis
    local cs = get_cross_sections(abs_widget_geo, mode)

    -- Set the offset
    local xoff, yoff = args.xoffset or 0, args.yoffset or 0 --TODO add margins

    -- Get the 4 closest points from `center_point` around the wibox
    local regions = {
        left   = {x = xoff+cs.h.x           , y = yoff+cs.h.y            },
        right  = {x = xoff+cs.h.x+cs.h.width, y = yoff+cs.h.y            },
        top    = {x = xoff+cs.v.x           , y = yoff+cs.v.y            },
        bottom = {x = xoff+cs.v.x           , y = yoff+cs.v.y+cs.v.height},
    }

    -- Assume the section is part of a single screen until someone complain.
    -- It is much faster to compute and getting it wrong probably have no side
    -- effects.
    local s = geo.drawable and geo.drawable.screen or screen.getbycoord(
                                                        center_point.x,
                                                        center_point.y
                                                      )

    -- Compute the distance (dp) between the `center_point` and the sides.
    -- This is only relevant for "cursor" and "cursor_inside" modes.
    for k, v in pairs(regions) do
        local dx, dy = v.x - center_point.x, v.y - center_point.y

        v.distance = math.sqrt(dx*dx + dy*dy)
        v.width    = cs.v.width
        v.height   = cs.h.height
        v.screen   = s
    end

    return regions
end

--- Move a drawable to a relative position next to another one.
-- @tparam drawable d A wibox or client
-- @tparam table regions A table with position as key and regions (x,y,w,h) as value
-- @tparam[opt={}] table preferred_positions The preferred positions (position as key,
--  and index as value)
-- @treturn string The choosen position
-- @treturn string The choosen direction
function module.move_relative(d, regions, preferred_positions) --TODO inside/outside, replace by args, allow modes
    --args.geo, args.mode, args.drawable, args.regions, args.preferred_positions
    local w,h = d.width, d.height

    local pref_idx, pref_name = 99, nil

    local does_fit = {}
    for k,v in pairs(regions) do
        local geo, dir = positions[k..1](v, w, h)
        geo.width, geo.height = w, h
        local fit = fit_in_screen(v.screen, geo)

        -- Try the other compatible geometry
        if not fit then
            geo, dir = positions[k..2](v, w, h)
            geo.width, geo.height = w, h
            fit = fit_in_screen(v.screen, geo)
        end

        does_fit[k] = fit and {geo, dir} or nil

        if fit and preferred_positions[k] and preferred_positions[k] < pref_idx then
            pref_idx  = preferred_positions[k]
            pref_name = k
        end

        -- No need to continue
        if fit and preferred_positions[k] == 1 then break end
    end

    local pos_name = pref_name or next(does_fit)
    local pos, dir = unpack(does_fit[pos_name])

    if pos then
        d.x = math.ceil(pos.x)
        d.y = math.ceil(pos.y)
    end

    return pos_name, dir
end

return module
