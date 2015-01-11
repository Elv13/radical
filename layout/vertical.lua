local setmetatable = setmetatable
local print,ipairs  = print,ipairs
local scroll    = require( "radical.widgets.scroll"   )
local filter    = require( "radical.widgets.filter"   )
local wibox     = require( "wibox"                    )
local cairo     = require( "lgi"                      ).cairo
local base      = nil
local horizontal_item_layout= require( "radical.item.layout.horizontal" )

local module = {}

local function left(data)
  if data._current_item._tmp_menu then
    data = data._current_item._tmp_menu
    data.items[1].selected = true
    return true,data
  end
end

local function right(data)
  if data.parent_geometry and data.parent_geometry.is_menu then
    for k,v in ipairs(data.items) do
      if v._tmp_menu == data or v.sub_menu_m == data then
        v.selected = true
      end
    end
    data.visible = false
    data = data.parent_geometry
    return true,data
  else
    return false
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
  data:add_key_hook({}, "&"       , "press", up    ) -- Xephyr bug
  data:add_key_hook({}, "Down"    , "press", down  )
  data:add_key_hook({}, "KP_Enter", "press", down  ) -- Xephyr bug
  data:add_key_hook({}, "Left"    , "press", right )
  data:add_key_hook({}, "\""      , "press", right ) -- Xephyr bug
  data:add_key_hook({}, "Right"   , "press", left  )
  data:add_key_hook({}, "#"       , "press", left  ) -- Xephyr bug
end

--Get preferred item geometry
local function item_fit(data,item,self,width,height)
  local w, h = 0,0--item._internal.cache_w or 1,item._internal.cache_h or 1
  if data.visible then
    w, h = item._private_data._fit(self,width,height)
    item._internal.pix_cache = {} --Clear the pimap cache
  end

  return w, item.height or h
end

-- As of July 2013, LGI is too slow to redraw big menus at ok speed
-- This do a pixmap cache to allow pre-rendering
local function cache_pixmap(item)
  item._internal.pix_cache = {}
  item.widget._draw = item.widget.draw
  item.widget.draw = function(self,w, cr, width, height)
    if not w.visible or item._hidden then return end
    if item._internal.pix_cache[10*width+7*height+(item.selected and 8888 or 999)] then
      cr:set_source_surface(item._internal.pix_cache[10*width+7*height+(item.selected and 8888 or 999)])
      cr:paint()
    else
      local img5 = cairo.ImageSurface.create(cairo.Format.ARGB32, width, height)
      local cr5 = cairo.Context(img5)
      item.widget._draw(self,w, cr5, width, height)
      cr:set_source_surface(img5)
      cr:paint()
      item._internal.pix_cache[10*width+7*height+(item.selected and 8888 or 999)] = img5
      return
    end
  end
end

function module:setup_text(item,data,text_w)
  local text_w = item._internal.text_w

  text_w.draw = function(self,w, cr, width, height)
    if item.underlay then
      horizontal_item_layout.paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self,w, cr, width, height)
  end
  text_w.fit = function(self,width,height) return width,height end

  item.set_text = function (_,value)
    if data.disable_markup then
      text_w:set_text(value)
    else
      text_w:set_markup(value)
    end
    item._private_data.text = value
  end
  item:set_text(item._private_data.text)
  return text_w
end

function module:setup_item(data,item,args)
  if not base then
    base = require( "radical.base" )
  end
  --Create the background
  local item_layout = item.layout or data.item_layout or horizontal_item_layout
  item.widget = item_layout(item,data,args)--wibox.widget.background()
  cache_pixmap(item)

  --Event handling
  if data.select_on == base.event.HOVER then
    item.widget:connect_signal("mouse::enter", function(_,geo)
      item.y = geo.y
      item.selected = true
    end)
    item.widget:connect_signal("mouse::leave", function()
      item.selected = false
    end)
  else
    item.widget:connect_signal("mouse::enter", function(_,geo)
      item.y = geo.y
      item.hover = true
    end)
    item.widget:connect_signal("mouse::leave", function()
      item.hover = false
    end)
  end
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

  item._private_data._fit = wibox.widget.background.fit
  if item._internal.margin_w then
    item._internal.margin_w.fit = function(...)
      if (item.visible == false or item._filter_out == true or item._hidden == true) then
        return 0,0
      end
      return data._internal.layout.item_fit(data,item,...)
    end
  end

  -- Text need to take as much space as possible, override default
  module:setup_text(item,data)

  -- Necessary for :set_position()
  local fit_w,fit_h = data._internal.layout:fit()

  data.width = fit_w
  data.height = fit_h

  -- Enable scrollbar if necessary
  if data._internal.scroll_w and data.rowcount > data.max_items then
    data._internal.scroll_w.visible = true
    data._internal.scroll_w["up"]:emit_signal("widget::updated")
    data._internal.scroll_w["down"]:emit_signal("widget::updated")
  end

  -- Setup tooltip
  item.widget:set_tooltip(item.tooltip)

  -- Apply item style
  local item_style = item.item_style or data.item_style
  item_style(item,{})

  -- Compute the minimum width
  if data.auto_resize and item._internal.margin_w then
    local fit_w,fit_h = wibox.layout.margin.fit(item._internal.margin_w,9999,9999)
    local is_largest = item == data._internal.largest_item_w
    if fit_w < 1000 and (not data._internal.largest_item_w_v or data._internal.largest_item_w_v < fit_w) then
      data._internal.largest_item_w = item
      data._internal.largest_item_w_v = fit_w
    end
  end

  item.widget:emit_signal("widget::updated")
end

local function compute_geo(data,width,height,force_values)
  local w = data.default_width
  if data.auto_resize and data._internal.largest_item_w then
    w = data._internal.largest_item_w_v > data.default_width and data._internal.largest_item_w_v or data.default_width
  end
  
  local visblerow = data.visible_row_count
  
  local sw,sh = data._internal.suf_l:fit(9999,9999)
  local pw,ph = data._internal.pref_l:fit(9999,9999)
  if not data._internal.has_widget then
    return w,(total and total > 0 and total or visblerow*data.item_height) + ph + sh
  else
    local sumh = data.widget_fit_height_sum
    local h = (visblerow-#data._internal.widgets)*data.item_height + sumh
    return w,h
  end
end

local function new(data)
  if not base then
    base = require( "radical.base" )
  end
  local l,real_l = wibox.layout.fixed.vertical(),nil
  real_l = wibox.layout.fixed.vertical()
  local pref_l,suf_l = wibox.layout.fixed.vertical(),wibox.layout.fixed.vertical()
  real_l:add(pref_l)
  if data.max_items then
    data._internal.scroll_w = scroll(data)
    pref_l:add(data._internal.scroll_w["up"])
  end
  real_l:add(l)
  real_l:add(suf_l)
  if data.show_filter then
    if data.max_items then
      suf_l:add(data._internal.scroll_w["down"])
    end
    local filter_tb = filter(data)
    suf_l:add(filter_tb)
    data._internal.filter_tb = filter_tb.widget
  else
    if data.max_items then
      suf_l:add(data._internal.scroll_w["down"])
    end
  end
  real_l.fit = function(a1,a2,a3,force_values)
    if not data.visible then return 1,1 end
    local w,h = compute_geo(data,a2,a3,force_values)
    data:emit_signal("layout_size",w,h)
    return w,h
  end
  real_l.add = function(real_l,item)
    return wibox.layout.fixed.add(l,item.widget)
  end
  real_l.item_fit = item_fit
  real_l.setup_key_hooks = module.setup_key_hooks
  real_l.setup_item = module.setup_item
  data._internal.content_layout = l
  data._internal.suf_l,data._internal.pref_l=suf_l,pref_l

--   if data.spacing and l.set_spacing then
--     l:set_spacing(data.spacing)
--   end

  --SWAP / MOVE / REMOVE
  data:connect_signal("item::swapped",function(_,item1,item2,index1,index2)
    l.widgets[index1],l.widgets[index2] = l.widgets[index2],l.widgets[index1]
    l:emit_signal("widget::updated")
  end)
  data:connect_signal("item::moved",function(_,item,new_idx,old_idx)
    table.insert(l.widgets,new_idx,table.remove(l.widgets,old_idx))
    l:emit_signal("widget::updated")
  end)
  data:connect_signal("item::removed",function(_,item,old_idx)
    table.remove(l.widgets,old_idx)
    l:emit_signal("widget::updated")
  end)
  data:connect_signal("item::appended",function(_,item)
    l.widgets[#l.widgets+1] = item.widget
    l:emit_signal("widget::updated")
  end)
  data:connect_signal("widget::added",function(_,item,widget)
    wibox.layout.fixed.add(l,item.widget)
    l:emit_signal("widget::updated")
  end)
  data:connect_signal("prefix_widget::added",function(_,widget,args)
    table.insert(pref_l.widgets,1,widget)
    pref_l:emit_signal("widget::updated")
    real_l:emit_signal("widget::updated")
  end)
  data:connect_signal("suffix_widget::added",function(_,widget,args)
    suf_l:add(widget)
  end)
  data._internal.text_fit = function(self,width,height) return width,height end
  return real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
