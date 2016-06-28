local setmetatable = setmetatable
local math,pairs   = math,pairs
local color        = require( "gears.color" )
local wibox        = require( "wibox"       )
local beautiful    = require( "beautiful"   )

local module,colors = {},nil

local function draw_label(cr,angle,radius,center_x,center_y,text)
    cr:set_source_rgba(1,1,1,1)
    cr:move_to(center_x+(radius/2)*math.cos(angle),center_y+(radius/2)*math.sin(angle))
    cr:line_to(center_x+(1.5*radius)*math.cos(angle),center_y+(1.5*radius)*math.sin(angle))
    local x,y = cr:get_current_point()
    cr:line_to(x+(x>center_x and radius/2 or -radius/2),y)
    local extents = cr:font_extents()
    cr:move_to(x+(x>center_x and radius/2 + 5 or (-radius/2 - cr:text_extents(text).width - 5)),y+(extents.height/4))
    cr:show_text(text)
    cr:stroke()
    cr:arc(center_x+(radius/2)*math.cos(angle),center_y+(radius/2)*math.sin(angle),2,0,2*math.pi)
    cr:arc(x+(x>center_x and radius/2 or -radius/2),y,2,0,2*math.pi)
    cr:fill()
end

local function draw_pie(cr,start_rad,end_rad,radius,col,center_x,center_y)
    cr:arc(center_x,center_y,radius,start_rad,end_rad)
    cr:line_to(center_x,center_y)
    cr:line_to(center_x+radius*math.cos(start_rad),center_y+radius*math.sin(start_rad))
    cr:close_path()
    cr:set_source_rgba(1,1,1,1)
    cr:stroke_preserve()
    cr:set_source(col)
    cr:fill()
end

local function compute_sum(data)
    local ret = 0
    for k,v in pairs(data) do ret = ret + v end

    return ret
end

local function draw(self, context, cr, width, height)
    if not self._private.data then return end

    local radius = (height > width and width or height) / 4
    local sum, start, count = compute_sum(self._private.data),0,0

    for k,v in pairs(self._private.data) do
        local end_angle = start + 2*math.pi*(v/sum)
        draw_pie(cr,start,end_angle,radius,colors[math.mod(count,4)+1],width/2,height/2)
        draw_label(cr,start+(end_angle-start)/2,radius,width/2,height/2,k)
        start,count = end_angle,count+1
    end

end

local function set_data(self,data)
    self._private.data = data
    self:emit_signal("widget::redraw_needed")
end

local function new(data)
    if not colors then colors = {color(beautiful.fg_normal),color(beautiful.bg_alternate),color(beautiful.fg_focus),color(beautiful.bg_highlight)} end
    local im = wibox.widget.imagebox()
    im.draw,im.set_data = draw,set_data

    return im
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
