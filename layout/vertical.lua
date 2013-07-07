local setmetatable = setmetatable
local print,pairs  = print,pairs
local unpack       = unpack
local util      = require( "awful.util"               )
local button    = require( "awful.button"             )
local checkbox  = require( "radical.widgets.checkbox" )
local scroll    = require( "radical.widgets.scroll"   )
local filter    = require( "radical.widgets.filter"   )
local fkey      = require( "radical.widgets.fkey"     )
local beautiful = require("beautiful"                 )
local wibox     = require( "wibox"                    )
local color     = require( "gears.color"              )
local cairo      = require( "lgi"                     ).cairo

local module = {}

local function left(data)
  if data._current_item._tmp_menu then
    data = data._current_item._tmp_menu
    data.items[1][1].selected = true
    return true,data
  end
end

local function right(data)
  if data.parent_geometry.is_menu then
    for k,v in ipairs(data.items) do
      if v[1]._tmp_menu == data or v[1].sub_menu_m == data then
        v[1].selected = true
      end
    end
    data.visible = false
    data = data.parent_geometry
    return true,data
  end
end

local function up(data)
  data.previous_item.selected = true
end

local function down(data)
  data.next_item.selected = true
end

function module:setup_key_hooks(data)
  data:add_key_hook({}, "Up"      , "press", up    )
  data:add_key_hook({}, "&"       , "press", up    )
  data:add_key_hook({}, "Down"    , "press", down  )
  data:add_key_hook({}, "KP_Enter", "press", down  )
  data:add_key_hook({}, "Left"    , "press", left  )
  data:add_key_hook({}, "\""      , "press", left  )
  data:add_key_hook({}, "Right"   , "press", right )
  data:add_key_hook({}, "#"       , "press", right )
end

--Get preferred item geometry
local function item_fit(data,item,...)
  local w, h = item._internal.cache_w or 1,item._internal.cache_h or 1
  if item._internal.has_changed and data.visible then
    w, h = item._private_data._fit(...)
    item._internal.has_changed = false
    item._internal.pix_cache = {} --Clear the pimap cache
  end
  return w, item._private_data.height or h
end

-- Like an overlay, but under
local function paint_underlay(data,item,cr,width,height)
  cr:save()
  cr:set_source_surface(item.underlay,width-item.underlay:get_width()-3)
  cr:paint_with_alpha(data.underlay_alpha)
  cr:restore()
end

-- As of July 2013, LGI is too slow to redraw big menus at ok speed
-- This do a pixmap cache to allow pre-rendering
local function cache_pixmap(item)
  item._internal.pix_cache = {}
  item.widget._draw = item.widget.draw
  item.widget.draw = function(self,wibox, cr, width, height)
    if not wibox.visible or item._hidden then return end
    if item._internal.pix_cache[10*width+7*height+(item.selected and 8888 or 999)] then
      cr:set_source_surface(item._internal.pix_cache[10*width+7*height+(item.selected and 8888 or 999)])
      cr:paint()
    else
      local img5 = cairo.ImageSurface.create(cairo.Format.ARGB32, width, height)
      local cr5 = cairo.Context(img5)
      item.widget._draw(self,wibox, cr5, width, height)
      cr:set_source_surface(img5)
      cr:paint()
      item._internal.pix_cache[10*width+7*height+(item.selected and 8888 or 999)] = img5
      return
    end
  end
end


function module:setup_item(data,item,args)
  --Create the background
  item.widget = wibox.widget.background()
  cache_pixmap(item)
  
  data.item_style(data,item,false,false)
  item.widget:set_fg(item._private_data.fg)
  item._internal.has_changed = true

  --Event handling
  item.widget:connect_signal("mouse::enter", function() item.selected = true end)
  item.widget:connect_signal("mouse::leave", function() item.selected = false end)
  data._internal.layout:add(item)

  --Be sure to always hide sub menus, even when data.visible is set manually
  data:connect_signal("visible::changed",function(_,vis)
    if data._tmp_menu and data.visible == false then
      data._tmp_menu.visible = false
    end
  end)
  data:connect_signal("parent_geometry::changed",function(_,vis)
    local fit_w,fit_h = data._internal.layout:fit()
    data.height = fit_h
    data.style(data)
  end)

  --Create the main item layout
  local l,la,lr = wibox.layout.fixed.horizontal(),wibox.layout.align.horizontal(),wibox.layout.fixed.horizontal()
  local m = wibox.layout.margin(la)
  m:set_margins (0)
  m:set_left  ( data.item_style.margins.LEFT   )
  m:set_right ( data.item_style.margins.RIGHT  )
  m:set_top   ( data.item_style.margins.TOP    )
  m:set_bottom( data.item_style.margins.BOTTOM )
  local text_w = wibox.widget.textbox()

  text_w.draw = function(self,w, cr, width, height)
    if item.underlay then
      paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self,w, cr, width, height)
  end
  text_w.fit = function(self,width,height) return width,height end

  item._private_data._fit = wibox.widget.background.fit
  m.fit = function(...)
    if not data.visible or (item.visible == false or item._filter_out == true or item._hidden == true) then
      return 0,0
    end
    return data._internal.layout.item_fit(data,item,...)
  end

  if data.fkeys_prefix == true then
    l:add(fkey(data,item))
    m:set_left  ( 0 )
  end

  if args.prefix_widget then
    l:add(args.prefix_widget)
  end

  local icon = wibox.widget.imagebox()
  icon.fit = function(...)
    local w,h = wibox.widget.imagebox.fit(...)
    return w+3,h
  end
  if args.icon then
    icon:set_image(args.icon)
  end
  l:add(icon)
  if item._private_data.sub_menu_f or item._private_data.sub_menu_m then
    local subArrow  = wibox.widget.imagebox() --TODO, make global
    subArrow.fit = function(box, w, h) return subArrow._image:get_width(),item.height end
    subArrow:set_image( beautiful.menu_submenu_icon   )
    lr:add(subArrow)
    item.widget.fit = function(box,w,h,...)
      args.y = data.height-h-data.margins.top
      return wibox.widget.background.fit(box,w,h)
    end
  end
  if item.checkable then
    item._internal.get_map.checked = function()
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked()
      else
        return item._private_data.checked
      end
    end
    local ck = wibox.widget.imagebox()
    ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    lr:add(ck)
    item._internal.set_map.checked = function (value)
      item._private_data.checked = value
      ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
      item._internal.has_changed = true
    end
  end
  if args.suffix_widget then
    lr:add(args.suffix_widget)
  end
  la:set_left(l)
  la:set_middle(text_w)
  la:set_right(lr)
  item.widget:set_widget(m)
  local fit_w,fit_h = data._internal.layout:fit()
  data.width = fit_w
  data.height = fit_h
  data.style(data)
  item._internal.set_map.text = function (value)
    text_w:set_markup(value)
    if data.auto_resize then
      local fit_w,fit_h = wibox.widget.textbox.fit(text_w,9999,9999)
      local is_largest = item == data._internal.largest_item_w
      item._internal.has_changed = true
      if not data._internal.largest_item_w_v or data._internal.largest_item_w_v < fit_w then
        data._internal.largest_item_w = item
        data._internal.largest_item_w_v = fit_w
      end
      --TODO find new largest is item is smaller
  --     if data._internal.largest_item_h_v < fit_h then
  --       data._internal.largest_item_h =item
  --       data._internal.largest_item_h_v = fit_h
  --     end
    end
  end
  
  item._internal.set_map.f_key = function(value)
    item._internal.has_changed = true
    item._internal.f_key = value
    data:remove_key_hook("F"..value)
    data:add_key_hook({}, "F"..value      , "press", function()
      item.button1()
      data.visible = false
    end)
  end
  item._internal.get_map.f_key = function() return item._internal.f_key end
  
  item._internal.set_map.icon = function (value)
    icon:set_image(value)
  end
  item._internal.set_map.text(item._private_data.text)
end

local function compute_geo(data)
  local w = data.default_width
  if data.auto_resize and data._internal.largest_item_w then
    w = data._internal.largest_item_w_v+100 > data.default_width and data._internal.largest_item_w_v+100 or data.default_width
  end
  local visblerow = data.filter_string == "" and data.rowcount or data._internal.visible_item_count
  if data.max_items and data.max_items < data.rowcount then
    visblerow = data.max_items
    if data.filter_string ~= "" then
      local cur,vis = (data._start_at or 1),0
      while (data._internal.items[cur] and data._internal.items[cur][1]) and cur < data.max_items + (data._start_at or 1) do
        vis = vis + (data._internal.items[cur][1]._filter_out and 0 or 1)
        cur = cur +1
      end
      visblerow = vis
    end
  end
  if not data._internal.has_widget then
    return w,(total and total > 0 and total or visblerow*data.item_height) + (data._internal.filter_tb and data.item_height or 0) + (data.max_items and data._internal.scroll_w["up"].visible and (2*data.item_height) or 0)
  else
    local h = (visblerow-#data._internal.widgets)*data.item_height
    for k,v in ipairs(data._internal.widgets) do
      local fw,fh = v.widget:fit(9999,9999)
      h = h + fh
    end
    return w,h
  end
end

local function new(data)
  local l,real_l = wibox.layout.fixed.vertical(),nil
  real_l = wibox.layout.fixed.vertical()
  if data.max_items then
    data._internal.scroll_w = scroll(data)
    real_l:add(data._internal.scroll_w["up"])
  end
  real_l:add(l)
  if data.show_filter then
    if data.max_items then
      real_l:add(data._internal.scroll_w["down"])
    end
    local filter_tb = filter(data)
    real_l:add(filter_tb)
    data._internal.filter_tb = filter_tb.widget
  else
    if data.max_items then
      real_l:add(data._internal.scroll_w["down"])
    end
  end
  real_l.fit = function(a1,a2,a3)
    if not data.visible then return 1,1 end
    local result,r2 = wibox.layout.fixed.fit(a1,99999,99999)
    local total = data._total_item_height
    return compute_geo(data)
  end
  real_l.add = function(real_l,item)
    return wibox.layout.fixed.add(l,item.widget)
  end
  real_l.item_fit = item_fit
  real_l.setup_key_hooks = module.setup_key_hooks
  real_l.setup_item = module.setup_item
  return real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
