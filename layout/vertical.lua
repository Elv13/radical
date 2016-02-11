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
local function item_fit(data,item,self,context, width,height)
  local w, h = 0,0--item._internal.cache_w or 1,item._internal.cache_h or 1
  if data.visible then
    w, h = item._private_data._fit({},self,context,width,height)
    item._internal.pix_cache = {} --Clear the pimap cache
  end

  return w, item.height or h
end

function module:setup_text(item,data,text_w)
  local text_w = item._internal.text_w

  text_w.draw = function(self,context, cr, width, height)
    if item.underlay then
      horizontal_item_layout.paint_underlay(data,item,cr,width,height)
    end
    wibox.widget.textbox.draw(self, context, cr, width, height)
  end
  text_w.fit = function(self,context,width,height) return width,height end

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
  item.widget = item_layout(item,data,args)

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
    local fit_w = wibox.layout.margin.fit(item._internal.margin_w,{},9999,9999)
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

  local sw,sh = data._internal.suf_l:get_preferred_size()
  local pw,ph = data._internal.pref_l:get_preferred_size()
  if not data._internal.has_widget then
    return w,(total and total > 0 and total or visblerow*data.item_height) + ph + sh
  else
    local sumh = data.widget_fit_height_sum
    local h = (visblerow-#data._internal.widgets)*data.item_height + sumh
    return w,h
  end
end

local function new(data)
    base = base or require( "radical.base" )

    local real_l = wibox.layout.fixed.vertical()

    local function real_fit(self,context,o_w,o_h,force_values)
        if not data.visible then return 1,1 end
        local w,h = compute_geo(data,o_w,o_h,force_values)
        data:emit_signal("layout_size",w,h)
        return w,h
    end

    local function real_add(self, item)
        return wibox.layout.fixed.add(data._internal.content_layout, item.widget)
    end

    -- Create the scroll widgets
    if data.max_items then
        data._internal.scroll_w = scroll(data)
    end

    real_l : setup {
        -- Widgets
        {
            -- The prefix section, used for the scroll widgets and custom prefixes

            -- Widgets
            data._internal.scroll_w and data._internal.scroll_w["up"] or nil,

            -- Attributes
            id     = "prefix_layout",
            layout = wibox.layout.fixed.vertical
        },
        {
            -- The main layout (where items are added)

            -- Attributes
            id      = "content_layout",
            spacing = data.spacing and data.spacing or 0,
            layout  = wibox.layout.fixed.vertical       ,
        },
        {
            -- The suffix section, used for the scroll widgets and custom suffixes

            -- Widgets
            data._internal.scroll_w and data._internal.scroll_w["down"] or nil,
            data.show_filter and {
                id     = "filter_widget",
                widget = filter(data) --FIXME for some reason it doesn't show up
            } or nil,

            -- Attributes
            id     = "suffix_layout"            ,
            layout = wibox.layout.fixed.vertical,
        },

        -- Attributes
        id              = "real_l"                   ,
        layout          = wibox.layout.fixed.vertical,

        -- Methods
        item_fit        = item_fit              ,
        setup_key_hooks = module.setup_key_hooks,
        setup_item      = module.setup_item     ,
    }

    -- Set the important widgets
    data._internal.content_layout = real_l:get_children_by_id( "content_layout" )[1]
    data._internal.suf_l          = real_l:get_children_by_id( "suffix_layout"  )[1]
    data._internal.pref_l         = real_l:get_children_by_id( "prefix_layout"  )[1]
    data._internal.filter_tb      = real_l:get_children_by_id( "filter_widget"  )[1]

    -- Set the overloaded methods
    real_l.real_l.fit = real_fit
    real_l.real_l.add = real_add

    local l = data._internal.content_layout

    --SWAP / MOVE / REMOVE
    data:connect_signal("item::swapped",function(_,item1,item2,index1,index2)
        l:swap(index1, index2)
    end)

    data:connect_signal("item::moved",function(_,item,new_idx,old_idx)
        local w = l:get_children()[old_idx]
        l:remove(old_idx)
        l:insert(new_idx, w)
    end)

    data:connect_signal("item::removed",function(_,item,old_idx)
        l:remove(old_idx)
    end)

    data:connect_signal("item::appended",function(_,item)
        l:add(item.widget)
    end)

    data:connect_signal("widget::added",function(_,item,widget)
        wibox.layout.fixed.add(l,item.widget)
        l:emit_signal("widget::updated")
    end)

    data:connect_signal("prefix_widget::added",function(_,widget,args)
        data._internal.pref_l:insert(1,widget)
    end)

    data:connect_signal("suffix_widget::added",function(_,widget,args)
        data._internal.suf_l:add(widget)
    end)

    data._internal.text_fit = function(self, context, width, height)
        return width,height
    end

    return real_l.real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
