local setmetatable = setmetatable
local ipairs,pairs = ipairs,pairs
local table,print  = table,print
local math,string  = math,string
local unpack,type  = unpack,type
local base      = require( "radical.base"             )
local awful     = require( "awful"                    )
local util      = require( "awful.util"               )
local button    = require( "awful.button"             )
local checkbox  = require( "radical.widgets.checkbox" )
local beautiful = require( "beautiful"                )
local naughty   = require( "naughty"                  )
local wibox     = require( "wibox"                    )
local tag       = require( "awful.tag"                )
local color     = require( "gears.color"              )
local cairo     = require( "lgi"                      ).cairo

local default = {width=90,height=30,radius=40,base_radius=60}

local capi = { mouse = mouse, mousegrabber = mousegrabber }

local module={}

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
      data.indicator.cr:arc             ( data.width/2 + (default.base_radius-20)*math.cos(angle),data.width/2 + (default.base_radius-20)*math.sin(angle),5,0,2*math.pi  )
      data.indicator.cr:close_path()
      data.indicator.cr:fill()
      data.indicator.cr:set_line_width(4)
      data.indicator.cr:arc( data.width/2,data.height/2,default.radius + default.base_radius ,angle-0.15,angle+0.15  )
      data.indicator.cr:stroke()
      data.indicator.cr:arc             ( data.width/2+170,data.height/2,10,0,2*math.pi  )
      data.indicator.cr:close_path()
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
    local position = data.layers[layer].position
    local dat_layer = data.layers[layer]
    local outer_radius = layer*default.radius + default.base_radius
    local inner_radius = outer_radius - default.radius
    local start_angle  = ((2*math.pi)/(4*layer))*(position-1)
    local end_angle    = ((2*math.pi)/(4*layer))*(position)
    dat_layer.cr:set_operator(cairo.Operator.SOURCE)
    if data.layers[layer].selected == position then
      dat_layer.cr:set_source  ( color(beautiful.fg_focus)         )
    else
      dat_layer.cr:set_source_rgb((5+(21-5)/(4*layer)*position)/256,(10+(119-10)/(4*layer)*position)/256,(27+(209-27)/(4*layer)*position)/256)
    end
    dat_layer.cr:move_to         ( data.width/2, data.height/2                             )
    dat_layer.cr:arc             ( data.width/2,data.height/2,outer_radius,start_angle,end_angle   )
    dat_layer.cr:fill_preserve   (                                      )
    dat_layer.cr:set_source_rgb(90/256,51/256,83/256)
    dat_layer.cr:close_path()
    dat_layer.cr:stroke()
    clear_center(layer)
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
    local new_selected = (idx*4 or 1) - math.floor(((real_rad*(idx*4 or 1))/2*math.pi)/10)
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

  local function draw_text(cr,text, start_angle, end_angle, layer)
    local text = "1234567890123456789012345678901234567890123456789012345678901234567890"
    local img2 = cairo.ImageSurface(cairo.Format.ARGB32, 20, 20)
    local cr2 = cairo.Context(img2)
    local level =0
    local step = (2*math.pi)/(((math.pi*2*(default.base_radius +  default.radius*layer - 3 - level*12))/4)*0.65) --relation between arc and char width
    local testAngle = start_angle + 0.05
    cr2:select_font_face("monospace")
    for i=1,text:len() do
      cr2:set_operator(cairo.Operator.CLEAR)
      cr2:paint()
      cr2:set_operator(cairo.Operator.SOURCE)
      cr2:set_source_rgb(1,1,1)
      cr2:move_to(0,10)
      cr2:text_path(text:sub(i,i))
      cr2:fill()
      local matrix12 = cairo.Matrix()
      cairo.Matrix.init_rotate(matrix12, -testAngle )
      matrix12:translate(-data.width/2+(default.base_radius + default.radius*layer - 3 - level*12)*(math.sin( - testAngle)),-data.height/2+(default.base_radius +  default.radius*layer - 3 - level*12)*(math.cos( -testAngle)))
      local pattern = cairo.Pattern.create_for_surface(img2,20,20)
      pattern:set_matrix(matrix12)
      cr:set_source(pattern)
      cr:paint()
      testAngle=testAngle+step
      if testAngle+step > end_angle - 0.05 then
        testAngle = start_angle+0.05
        level = level +1
        if level > 2 then
          break
        end
      end
    end
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
    end
    cr:set_source_surface(create_inner_circle(),0,0)
    cr:paint()
    cr:set_source_surface(position_indicator_layer(),0,0)
    cr:paint()
    draw_text(cr,"",math.pi,3*(math.pi/2),1)
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
  })

  data:set_layer(2,{
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
  local get_map,set_map,private_data = internal.get_map,internal.set_map,internal.private_data

  --Init
--   internal.w = wibox({})
  internal.margin = wibox.layout.margin()
  if not data.layout then
    data.layout = layout.vertical
  end
  internal.layout = wibox.layout.fixed.horizontal() --data.layout(data) --TODO fix
  internal.margin:set_widget(internal.layout)

  --Getters
  get_map.wibox     = function() return nil end -- Will this break?
  get_map.x         = function() return 0 end
  get_map.y         = function() return 0 end
  get_map.width     = function() return 500 end
  get_map.height    = function() return 40 end
  get_map.visible   = function() return private_data.visible end
  get_map.direction = function() return private_data.direction end
  get_map.margins   = function()
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
