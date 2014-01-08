local setmetatable = setmetatable
local print,pairs = print,pairs
local unpack=unpack
local util      = require( "awful.util"       )
local button    = require( "awful.button"     )
local checkbox  = require( "radical.widgets.checkbox" )
local wibox     = require( "wibox" )

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

local function icon_fit(data,...)
  local w,h = wibox.widget.imagebox.fit(...)
  return w,data.icon_size or h
end

function module:setup_item(data,item,args)
    --Create the background
  item.widget = wibox.widget.background()
  data.item_style(data,item,{})
  item.widget:set_fg(item._private_data.fg)

  --Event handling
  item.widget:connect_signal("mouse::enter", function() item.selected = true end)
  item.widget:connect_signal("mouse::leave", function() item.selected = false end)
  data._internal.layout:add(item)
  local buttons = {}
  for i=1,10 do
    if args["button"..i] then
      buttons[#buttons+1] = button({},i,args["button"..i])
    end
  end
  if not buttons[3] then --Hide on right click
    buttons[#buttons+1] = button({},3,function()
      data.visible = false
      if data.parent_geometry and data.parent_geometry.is_menu then
        data.parent_geometry.visible = false
      end
    end)
  end

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
  item.widget:buttons( util.table.join(unpack(buttons)))

  --Create the main item layout
  local l,la,lr = wibox.layout.fixed.vertical(),wibox.layout.align.vertical(),wibox.layout.fixed.horizontal()
  local m = wibox.layout.margin(la)
  m:set_margins (0)
  m:set_left  ( data.item_style.margins.LEFT   )
  m:set_right ( data.item_style.margins.RIGHT  )
  m:set_top   ( data.item_style.margins.TOP    )
  m:set_bottom( data.item_style.margins.BOTTOM )
  local text_w = wibox.widget.textbox()
  text_w:set_align("center")
  item._private_data._fit = wibox.widget.background.fit
  m.fit = function(...)
      if item.visible == false or item._filter_out == true then
        return 0,0
      end
      return data._internal.layout.item_fit(data,item,...)
  end

  if data.fkeys_prefix == true then
    local pref = wibox.widget.textbox()
    pref.draw = function(self,w, cr, width, height)
      cr:set_source(color(beautiful.fg_normal))
      cr:paint()
      wibox.widget.textbox.draw(self,w, cr, width, height)
    end
    l:add(pref)
    m:set_left  ( 0 )
  end

  if args.prefix_widget then
    l:add(args.prefix_widget)
  end

  
  local icon_flex = wibox.layout.align.horizontal()
  local icon = wibox.widget.imagebox()
  icon.fit = function(...) return icon_fit(data,...) end
  if args.icon then
    icon:set_image(args.icon)
  end
  icon_flex:set_middle(icon)
  l:add(icon_flex)
  l:add(text_w)
  if item._private_data.sub_menu_f or item._private_data.sub_menu_m then
    local subArrow  = wibox.widget.imagebox() --TODO, make global
    subArrow.fit = function(box, w, h) return subArrow._image:get_width(),item.height end
    subArrow:set_image( beautiful.menu_submenu_icon   )
    lr:add(subArrow)
    item.widget.fit = function(box,w,h,...)
      args.y = data.height-h-data.margins.top
      return wibox.widget.background.fit(box,w,h,...)
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
    end
  end
  if args.suffix_widget then
    lr:add(args.suffix_widget)
  end
  la:set_top(l)
  la:set_bottom(lr)
  item.widget:set_widget(m)
  local fit_w,fit_h = data._internal.layout:fit()
  data.width = fit_w
  data.height = fit_h
  data.style(data)
  item._internal.set_map.text = function (value)
    if data.disable_markup then
      text_w:set_text(value)
    else
      text_w:set_markup(value)
    end
    if data.auto_resize then
      local fit_w,fit_h = text_w:fit(999,9999)
      local is_largest = item == data._internal.largest_item_h
      --TODO find new largest is item is smaller
      if not data._internal.largest_item_h_v or data._internal.largest_item_h_v < fit_h then
        data._internal.largest_item_h =item
        data._internal.largest_item_h_v = fit_h
      end
    end
  end
  item._internal.set_map.icon = function (value)
    icon:set_image(value)
  end
  item._internal.set_map.text(item._private_data.text)

  -- Setup tooltip
  item.widget:set_tooltip(item.tooltip)
end

--Get preferred item geometry
local function item_fit(data,item,...)
  if not data.visible then return 1,1 end
  local w, h = item._private_data._fit(...)
  return data.item_width or 70, item._private_data.height or h
end

local function new(data)
  local l = wibox.layout.fixed.horizontal()
  l.fit = function(a1,a2,a3)
    local result,r2 = wibox.layout.fixed.fit(a1,99999,99999)
--     return data.rowcount*(data.item_width or data.default_width),data.item_height
    if data.auto_resize and data._internal.largest_item_h then
      return data.rowcount*(data.item_width or data.default_width),data._internal.largest_item_h_v > data.item_height and data._internal.largest_item_h_v or data.item_height
    else
      return data.rowcount*(data.item_width or data.default_width),data.item_height
    end
  end
  l.add = function(l,item)
    return wibox.layout.fixed.add(l,item.widget)
  end
  l.item_fit = item_fit
  l.setup_key_hooks = module.setup_key_hooks
  l.setup_item = module.setup_item
  return l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
