local setmetatable = setmetatable
local ipairs,pairs = ipairs,pairs
local table,print  = table,print
local math,string  = math,string
local unpack,type  = unpack,type
local base      = require( "radical.base"             )
local awful     = require( "awful"                    )
local util      = require( "awful.util"               )
local button    = require( "awful.button"             )
local checkbox  = require( "wibox.widget.checkbox"    )
local beautiful = require( "beautiful"                )
local naughty   = require( "naughty"                  )
local wibox     = require( "wibox"                    )
local tag       = require( "awful.tag"                )
local color     = require( "gears.color"              )
local cairo     = require( "lgi"                      ).cairo
local shape     = require( "gears.shape"              )

local default = {width=90,height=30,radius=40,base_radius=60}

local capi = { mouse = mouse, mousegrabber = mousegrabber }

local module={}

-- Generate a cached pixmap starting at pi/2-(2*pi / seg_count)
-- This mask is then rotated in place where desired
-- the reason for this is to keep the code simple and allow
-- a menu rotate "animation" with the scroll wheel
local function gen_text_mask(data, layer, segs, text)

  -- Step 1: compute the minimal size
  --TODO limit to the radius
  local h  = (default.base_radius + layer*default.radius) * (segs < 2 and 2 or 1)

  -- I let the reader make the proof of this: good luck with that
  local dr = (math.pi*2)/segs
  local w  = segs <= 2 and data.width or 2*math.abs(math.sin((dr)/3)*(data.width/2)) + 3

  -- Step 2: Create the surface
  local img = cairo.ImageSurface(cairo.Format.ARGB32, w, h)
  local cr  = cairo.Context(img)

--   cr:set_source_rgba(1,0,0,1)
--   cr:paint()
--   cr:set_source_rgba(1,1,1,1)

  local border_width= 4
  local start_angle = -(math.pi/2) - dr/2
  local end_angle   = -(math.pi/2) + dr/2
  local cur_angle   = start_angle
  local cur_rad     = h-border_width

  cr:set_source_rgba(1,1,1,1)

  cr:select_font_face("monospace")

  local matrix = cairo.Matrix()
  cairo.Matrix.init_translate(matrix,w/2,h)

  for i=1,text:len() do
    local c = text:sub(i,i)

    -- Step 4: Create the transformation matrix
    -- TODO use composite
    local matrix12 = cairo.Matrix()
    local ex = cr:text_extents(c)
    cairo.Matrix.init_rotate(matrix12, cur_angle+math.pi/2)
    matrix12:translate(-ex.width/2,ex.height/2)

    local trext = cairo.Matrix()
    cairo.Matrix.init_translate(trext,
      cur_rad*math.cos(cur_angle),
      cur_rad*math.sin(cur_angle)
    )

    local res = cairo.Matrix()
    res:multiply(trext,matrix)

    local res2 = cairo.Matrix()
    res2:multiply(matrix12,res)
    cr:set_matrix(res2)

    -- Step 4: Paint
    cr:text_path(c)
    cr:fill()

    -- Step 5: update the angle
    cur_angle = cur_angle + 0.05 --TODO use trigonometry to copute this
    if cur_angle > end_angle then
      cur_angle = start_angle
      cur_rad = cur_rad - border_width - ex.height
    end
  end
  return img
end

function module.radial_client_select(args)
  --Settings
  local args = args or {}
  local data = {width=400,height=400,layers={},compose={}}
  local screen = args.screen or mouse.screen
  local height = args.height or default.height
  local width  = args.widget or default.width

  local function position_indicator_layer()
    if not data.indicator or data.angle_cache ~= data.angle then
      local angle,tan = data.angle or 0,data.tan or 0
      if not data.indicator then
        data.indicator = {}
        data.indicator.img = cairo.ImageSurface(cairo.Format.ARGB32, data.width, data.height)
        data.indicator.cr = cairo.Context(data.indicator.img)
      else
        data.indicator.cr:set_operator(cairo.Operator.CLEAR)
        data.indicator.cr:paint()
        data.indicator.cr:set_operator(cairo.Operator.SOURCE)
      end
      data.indicator.cr:set_source_rgb(1,0,0)

      -- The Inner dot around the dotted circle
      local littledot_rad = 5
      local dot = shape.transform(shape.circle) : translate(
        data.width/2 + (default.base_radius-20)*math.cos(angle) -littledot_rad,
        data.width/2 + (default.base_radius-20)*math.sin(angle) -littledot_rad
      )

      dot(data.indicator.cr, 2*littledot_rad, 2*littledot_rad)
      data.indicator.cr:fill()

      -- The little arc on top of the border
      data.indicator.cr:set_line_width(4)
      data.indicator.cr:arc( data.width/2,data.height/2,default.radius + default.base_radius ,angle-0.15,angle+0.15  )
      data.indicator.cr:stroke()

      -- The Big red dot TODO make it move
      dot = shape.transform(shape.circle) : translate(
        data.width/2+170 -2*littledot_rad,
        data.height/2    -2*littledot_rad
      )
      dot(data.indicator.cr, 4*littledot_rad, 4*littledot_rad)
      data.indicator.cr:fill()
      data.angle_cache = data.angle
    end
    return data.indicator.img
  end

  local function create_inner_circle()
    if not data.inner then
      data.inner = {}
      data.inner.img = cairo.ImageSurface(cairo.Format.ARGB32, data.width, data.height)
      data.inner.cr = cairo.Context(data.inner.img)
      data.inner.cr:set_line_width(3)
      data.inner.cr:set_source_rgb(0.9,0.9,0.9)

      data.inner.cr:arc             ( data.width/2,data.height/2,default.base_radius,0,2*math.pi  )
      data.inner.cr:close_path()
      data.inner.cr:stroke()
      data.inner.cr:arc             ( data.width/2,data.height/2,default.base_radius-20,0,2*math.pi  )
      data.inner.cr:close_path()
      data.inner.cr:set_dash({10,4},1)
      data.inner.cr:stroke()
    end
    return data.inner.img
  end

  local function clear_center(layer)
    local dat_layer = data.layers[layer]
    local rad = default.base_radius+(layer-1)*default.radius
    dat_layer.cr:set_operator(cairo.Operator.CLEAR)
    dat_layer.cr:set_source_rgba ( 0  , 0  , 0,1                             )
    dat_layer.cr:move_to         ( data.width/2, data.height/2               )
    dat_layer.cr:arc             (data.width/2,data.height/2,rad,0,2*math.pi )
    dat_layer.cr:fill            (                                           )
  end


  local function gen_arc(layer)
    data.layers[layer].position = (data.layers[layer].position or 0) + 1
    local sef_count = #data.layers[layer].content
    local position = data.layers[layer].position
    local dat_layer = data.layers[layer]
    local outer_radius = layer*default.radius + default.base_radius
    local inner_radius = outer_radius - default.radius
    local start_angle  = ((2*math.pi)/sef_count)*(position-1)
    local end_angle    = ((2*math.pi)/sef_count)*(position)
    dat_layer.cr:set_operator(cairo.Operator.SOURCE)
    if data.layers[layer].selected == position then
      dat_layer.cr:set_source  ( color(beautiful.fg_focus)         )
    else
      dat_layer.cr:set_source_rgb((5+(21-5)/sef_count*position)/256,(10+(119-10)/sef_count*position)/256,(27+(209-27)/sef_count*position)/256)
    end
    dat_layer.cr:move_to         ( data.width/2, data.height/2                             )
    dat_layer.cr:arc             ( data.width/2,data.height/2,outer_radius,start_angle,end_angle   )
    dat_layer.cr:fill_preserve   (                                      )
    dat_layer.cr:set_source_rgb(90/256,51/256,83/256)
    dat_layer.cr:close_path()
    dat_layer.cr:stroke()
    clear_center(layer)
  end

  local function draw_text(cr,text, start_angle, end_angle, layer)
    if not text then return end

    local img2 = cairo.ImageSurface(cairo.Format.ARGB32, 20, 20)
    local cr2 = cairo.Context(img2)
    local level =0
    local step = (2*math.pi)/(((math.pi*2*(default.base_radius +  default.radius*layer - 3 - level*12))/4)*0.65) --relation between arc and char width
    local testAngle = start_angle + 0.05
    cr2:select_font_face("monospace")
    local img = gen_text_mask(data,layer,#data.layers[layer].content,text)
    cr:set_source_surface(img,100,60)
    cr:paint()
--     for i=1,text:len() do
--       cr2:set_operator(cairo.Operator.CLEAR)
--       cr2:paint()
--       cr2:set_operator(cairo.Operator.SOURCE)
--       cr2:set_source_rgb(1,1,1)
--       cr2:move_to(0,10)
--       cr2:text_path(text:sub(i,i))
--       cr2:fill()
--       local matrix12 = cairo.Matrix()
--       cairo.Matrix.init_rotate(matrix12, -testAngle )
--       matrix12:translate(-data.width/2+(default.base_radius + default.radius*layer - 3 - level*12)*(math.sin( - testAngle)),-data.height/2+(default.base_radius +  default.radius*layer - 3 - level*12)*(math.cos( -testAngle)))
--       local pattern = cairo.Pattern.create_for_surface(img2,20,20)
--       pattern:set_matrix(matrix12)
--       cr:set_source(pattern)
--       cr:paint()
--       testAngle=testAngle+step
--       if testAngle+step > end_angle - 0.05 then
--         testAngle = start_angle+0.05
--         level = level +1
--         if level > 2 then
--           break
--         end
--       end
--     end
  end

  local function repaint_layer(idx,content)
    local lay = data.layers[idx]
    if not lay then
      data.layers[idx] = {}
      lay = data.layers[idx]
      lay.img = cairo.ImageSurface(cairo.Format.ARGB32, data.width, data.height)
      lay.cr = cairo.Context(lay.img)
      lay.cr:set_line_width(3)
    end
    local real_rad = data.angle or 0
    if real_rad >= 0 then
      real_rad = math.pi*2 - real_rad
    else
      real_rad = -real_rad
    end
    local count = #(lay.content or {})

    local new_selected = count - math.floor( (real_rad)/(2*math.pi) * count )

    if content or (lay.content and new_selected ~= lay.selected) then
      lay.content = content or lay.content
      lay.cr:set_operator(cairo.Operator.CLEAR)
      lay.cr:paint()
      lay.position = 0
      lay.selected = new_selected
      for k,v in ipairs(lay.content) do
          gen_arc(idx,v)
      end
      lay.count = #lay.content
    end
    return lay.img
  end

  local function compose()
    if not data.compose.img then
      data.compose.img = cairo.ImageSurface(cairo.Format.ARGB32, data.width, data.height)
      data.compose.cr  = cairo.Context(data.compose.img)
    else
      data.compose.cr:set_operator(cairo.Operator.CLEAR)
      data.compose.cr:paint()
      data.compose.cr:set_operator(cairo.Operator.OVER)
    end
    local cr = data.compose.cr
    for i=#data.layers,1,-1 do
      cr:set_source_surface(repaint_layer(i),0,0)
      cr:paint()

      for k,v in ipairs(data.layers[i].content) do
        local dr = (2*math.pi)/#data.layers[i].content
--         print("BLA BLA",k,i)
        local r1 = dr*(k-1)
--         print(i,k,r1)
        if i == 2 and k == 1 then
          draw_text(cr,"1234567890123456789012345678901234567890123456789012345678901234567890",r1,r1+dr,i)
        end
      end
    end
    cr:set_source_surface(create_inner_circle(),0,0)
    cr:paint()
    cr:set_source_surface(position_indicator_layer(),0,0)
    cr:paint()
  end

  function data:set_layer(idx,content)
    if not data.w then
      data.w =wibox({})
      data.w.ontop    = true
      data.w.visible  = true
      data.w.width    = data.width-- width
      data.w.height   = data.height
      data.w.x = capi.mouse.coords().x - data.width/2
      data.w.y = capi.mouse.coords().y - data.height/2
      data.ib = data.ib or wibox.widget.imagebox()
      data.w:set_widget(data.ib)
    end
    repaint_layer(idx,content)
  end

  data:set_layer(1,{
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
  })

  data:set_layer(2,{
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
    {name="test",icon="",func =  function(menu,...)  end },
  })

  local focal = nil
  capi.mousegrabber.run(function(mouse)
    if not focal then
        focal = {x= mouse.x,y=mouse.y}
    end
    if mouse.buttons[3] == true then
        capi.mousegrabber.stop()
        focal = nil
        return false
    end
    local angle = math.atan2((mouse.y-focal.y),(mouse.x-focal.x))
    data.tan    = (mouse.y-focal.y)/(mouse.x-focal.x)
    data.angle  = angle
    compose()

    data.ib:set_image(data.compose.img)
    data.w.shape_bounding = data.compose.img._native
    return true
  end,"fleur")

  return data
end



















local function get_direction(data)
  return "left" -- Nothing to do
end

local function set_position(self)
  return --Nothing to do
end

local function setup_drawable(data)
  local internal = data._internal
  local private_data = internal.private_data

  --Init
--   internal.w = wibox({})
  internal.margin = wibox.container.margin()
  if not data.layout then
    data.layout = layout.vertical
  end
  internal.layout = wibox.layout.fixed.horizontal() --data.layout(data) --TODO fix
  internal.margin:set_widget(internal.layout)

  --Getters
  data.get_wibox     = function() return nil end -- Will this break?
  data.get_x         = function() return 0 end
  data.get_y         = function() return 0 end
  data.get_width     = function() return 500 end
  data.get_height    = function() return 40 end
  data.get_visible   = function() return private_data.visible end
  data.get_direction = function() return private_data.direction end
  data.get_margins   = function()
    local ret = {left=data.border_width,right=data.border_width,top=data.style.margins.TOP,bottom=data.style.margins.BOTTOM}
    if data.arrow_type ~= base.arrow_type.NONE then
      ret[data.direction] = ret[data.direction]+13
    end
    return ret
  end

  --Setters
  function internal:set_visible(value)
    -- TODO
  end

end

local function setup_item(data,item,args)
  -- Add widgets
  local tb = wibox.widget.textbox()
  data._internal.layout:add(tb)
  item.widget = tb
  tb:set_text("bob")
end

local function new(args)
    local args = args or {}
    args.internal = args.internal or {}
    args.internal.get_direction  = args.internal.get_direction  or get_direction
    args.internal.set_position   = args.internal.set_position   or set_position
    args.internal.setup_drawable = args.internal.setup_drawable or setup_drawable
    args.internal.setup_item     = args.internal.setup_item     or setup_item
    args.style = args.style or arrow_style
    local ret = base(args)
    ret:connect_signal("clear::menu",function(_,vis)
      ret._internal.layout:reset()
    end)
    ret:connect_signal("_hidden::changed",function(_,item)
      item.widget:emit_signal("widget::updated")
    end)
    return ret
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
