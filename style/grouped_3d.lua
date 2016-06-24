local setmetatable = setmetatable
local color  = require( "gears.color"  )

local module = {
  margins = {
    TOP    = 0 ,
    BOTTOM = 0 ,
    LEFT   = 0 ,
    RIGHT  = 0 ,
  }
}

local function rounded_rect(cr,x,y,w,h,radius) --TODO port to shape API
  cr:save()
  cr:translate(x,y)
  cr:move_to(0,radius)
  cr:arc(radius,radius,radius,math.pi,3*(math.pi/2))
  cr:arc(w-radius,radius,radius,3*(math.pi/2),math.pi*2)
  cr:arc(w-radius,h-radius,radius,math.pi*2,math.pi/2)
  cr:arc(radius,h-radius,radius,math.pi/2,math.pi)
  cr:close_path()
  cr:restore()
end

local function draw2(self, context, cr, width, height)
  cr:save()
  local mx,my = self.left or 0, self.top or 0
  local mw,mh = width - mx - (self.right or 0), height - my - (self.bottom or 0)
  rounded_rect(cr,mx,my,mw,mh,6)
  local path = cr:copy_path()
  cr:clip()

  if self.___draw then
    self.___draw(self, context, cr, width, height)
  end

  cr:append_path(path)
  cr:set_source(color(self.data.border_color))
  cr:stroke()
  cr:restore()
end

--TODO unported
local function draw(data)
  if not data._internal then return end

  local m = data._internal.margin
  if m then
    m.___draw = m.draw
    m.draw = draw2
    m.data = data
  end
end

return setmetatable(module, { __call = function(_, ...) return draw(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
