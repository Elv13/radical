local capi      = {screen = screen}
local wibox     = require( "wibox"             )
local util      = require( "awful.util"        )
local timer     = require( "gears.timer"       )
local placement = require( "awful.placement"   )

local module = {}

--TODO add "wrap cursor mode"

local wibox_to_req = {}

local corners_geo = {
    -- Corners
    top_left     = function(geo, wa) return {width = 1, height = 1} end,
    top_right    = function(geo, wa) return {width = 1, height = 1} end,
    bottom_left  = function(geo, wa) return {width = 1, height = 1} end,
    bottom_right = function(geo, wa) return {width = 1, height = 1} end,

    -- Sides
    left         = function(geo, wa) return {width = 1       , height = wa.height } end,
    right        = function(geo, wa) return {width = 1       , height = wa.height } end,
    top          = function(geo, wa) return {width = wa.width, height = 1         } end,
    bottom       = function(geo, wa) return {width = wa.width, height = 1         } end,
}

local function mouse_enter(w)
    local req = wibox_to_req[w]
    if req and req.enter then
        req:enter()
    end
end

local function mouse_leave(w)
    local req = wibox_to_req[w]
    if req and req.leave then
        req:leave()
    end
end

local function create_hot_corner(corner, s)
    s = s or 1

    local size  = corners_geo[corner] (
        capi.screen[s].geometry,
        capi.screen[s].workarea
    )

    local w = wibox(util.table.crush(size, {ontop=true, opacity = 0, visible=true}))

    placement[corner](w, {
        parent = capi.screen[s],
        attach = true,
    })

    local req = {wibox = w, screen = s, corner = corner}

    w:connect_signal("mouse::enter", mouse_enter)

    wibox_to_req[w] = req

    return req
end

local function create_visible_timer(w, time, req)
    local t = timer{}
    t.timeout = time
    t:connect_signal("timeout", function()
        w.visible = false
        req.wibox.visible = true
        t:stop()
    end)
    t:start()
end

function module.register_function(corner, f, s)
    if not f then return end
    local req = create_hot_corner(corner, s)
    req.enter = f

    return req
end

--- Show a wibox when `corner` is hit.
--
-- Valid corners are:
--
-- * left
-- * right
-- * top
-- * bottom
-- * top_left
-- * top_right
-- * bottom_left
-- * bottom_right
--
-- @tparam string corner A corner name
-- @param w The wibox or a function returning a wibox in case lazy loading is
--  desirable
-- @tparam[opt=all] number s The screen
-- @tparam[opt=0] number timeout The timeout (in seconds)
-- @return A request handler
function module.register_wibox(corner, w, s, timeout)
    if not w then return end
    local req = create_hot_corner(corner, s)
    local connected = false

    function req.enter()

        if type(w) == "function" then
            w = w(req)
        end

        if not connected then
            w:connect_signal("mouse::leave", mouse_leave)
            wibox_to_req[w] = req --FIXME leak
            connected = true
        end

        w.visible = true
    end

    if not timeout then
        function req.leave() w.visible = false; req.wibox.visible = true end
    else
        function req.leave() create_visible_timer(w, timeout, req) end
    end

    return req
end

return module
