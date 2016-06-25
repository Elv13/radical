local type = type
local beautiful = require("beautiful")
local theme = require("radical.theme")
local timer = require("gears.timer")
local object = require("radical.object")

local module = {
 -- style  = require("radical.item.style"),
 -- layout = require("radical.item.layout"),
  arrow_type = {
    NONE     = 0,
    PRETTY   = 1,
    CENTERED = 2,
  },
  event      ={
    NEVER    = 0,
    BUTTON1  = 1,
    BUTTON2  = 2,
    BUTTON3  = 3,
    SELECTED = 100,
    HOVER    = 1000,
    LEAVE    = 1001,
  },
  item_flags     = {
    NONE      = 999999 ,
    DISABLED  = 1 , -- Cannot be interacted with
    URGENT    = 2 , -- Need attention
    SELECTED  = 3 , -- Single item selected [[FOCUS]]
    HOVERED   = -1 , -- Mouse hover
    PRESSED   = 4 , -- Mouse pressed
    USED      = 6 , -- Common flag
    CHECKED   = 7 , -- When checkbox isn't enough
    ALTERNATE = 8 ,
    HIGHLIGHT = 9 ,
    HEADER    = 10,

    -- Implementation defined flags
    USR1     = 101,
    USR2     = 102,
    USR3     = 103,
    USR4     = 104,
    USR5     = 105,
    USR6     = 106,
    USR7     = 107,
    USR8     = 108,
    USR9     = 109,
    USR10    = 110,
  },
}

local function load_async(tab,key)
  if key == "style" then
    module.style = require("radical.item.style")
    return module.style
  elseif key == "layout" then
    module.layout = require("radical.item.layout")
    return module.layout
    --TODO handle colors this way
--   elseif key:sub(1,7 ) == "get_fg_" then
--     
--   elseif key:sub(1,7 ) == "get_bg_" then
--     
--   elseif key:sub(1,17) == "get_border_color_" then
--     
  end
  return rawget(module,key)
end

local function hide_sub_menu(item,data)
  if item._tmp_menu then
    item._tmp_menu.visible = false
    item._tmp_menu = nil
    data._tmp_menu = nil
    item:emit_signal("state::changed")
  end
end

local function set_infoshapes(item, shapes)
    if item.widget and item.widget.get_children_by_id then
        local infoshape_widget = item.widget:get_children_by_id("infoshapes")[1]
        if infoshape_widget then
            infoshape_widget:set_infoshapes(shapes)
        end
    end
end

-- local registered_items = {}
-- local is_watching = false
-- local mouse_tracker = object{}
-- local function watch_mouse(a,b,c)
--   print("move",a,b,c)
-- end

-- local function register_mouse_track()
--   if not is_watching then
--     
--   end
-- end

local function new_item(data,args)
  args = args or {}
  local item,private_data = object({
    private_data  = {
      text        = args.text        or ""                                                                  ,
--       height      = args.height      or data.item_height or beautiful.menu_height or 30                     ,
      width       = args.width       or nil                                                                 ,
      icon        = args.icon        or nil                                                                 ,
      prefix      = args.prefix      or ""                                                                  ,
      suffix      = args.suffix      or ""                                                                  ,
      bg          = args.bg          or nil                                                                 ,
      fg          = args.fg          or data.fg                                                             , --TODO don't do this
      border_color= args.border_color or data.item_border_color                                             ,
      border_width= args.border_width or data.item_border_width                                             ,
      bg_prefix   = args.bg_prefix   or data.bg_prefix                                                      ,
      sub_menu_m  = (args.sub_menu   and type(args.sub_menu) == "table" and args.sub_menu.is_menu) and args.sub_menu or nil,
      sub_menu_f  = (args.sub_menu   and type(args.sub_menu) == "function") and args.sub_menu or nil        ,
      checkable   = args.checkable   or (args.checked ~= nil) or false                                      ,
      checked     = args.checked     or false                                                               ,
      tooltip     = args.tooltip     or nil                                                                 ,
      style       = args.style       or data.item_style                                                     ,
      layout      = args.layout      or args.item_layout or nil                                             ,
      infoshapes  = args.infoshapes  or nil                                                                 ,
      shape       = args.shape       or data.item_shape                                                     ,
      overlay_draw= args.overlay_draw or data.overlay_draw                                                  ,
      item_border_color = args.item_border_color or data.item_border_color or nil                           ,
    },
    force_private = {
      visible = true,
      selected = true,
      index    = true,
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })
  item._private_data = private_data
  item._internal     = args._internal or {}
  theme.setup_item_colors(data,item,args)

  item.get_height = function()
    return args.height or data.item_height or beautiful.menu_height or 30
  end
  item.get_bg = function()
    return data.bg
  end
  item.get_fg = function()
    return data.fg
  end

  item.state         = theme.init_state(item)

  for i=1,10 do
    item["button"..i] = args["button"..i]
  end

  -- Invalidate the filter when there is still room for new items
  -- this is slow, but more reliable than it was before
  if data._internal.visible_item_count
   and data._internal.visible_item_count < (data.max_items or 9999999) then
    data._internal.visible_item_count = nil
  end

  -- Need to be done before painting
  data._internal.items[#data._internal.items+1] = {}
  data._internal.items[#data._internal.items] = item

  -- Getters
  item.get_selected = function(_)
    return item.state[module.item_flags.SELECTED] == true
  end

  -- Setters
  item.set_selected = function(_,value,force)
    private_data.selected = value

    -- Hide the sub-menu
    local current_item = data._current_item
    if current_item and current_item ~= item or force then
      current_item.state[module.item_flags.SELECTED] = nil
      current_item:emit_signal("selected::changed",false)
      hide_sub_menu(current_item,data)
    end

    -- Unselect item
    if value == false then
      item.state[module.item_flags.SELECTED] = nil
      return
    end
    item.state[module.item_flags.SELECTED] = true
    data._current_item = item
  end

  function item:set_hover(value)
    local item_style = item.item_style or data.item_style
    item.state[module.item_flags.HOVERED] = value and true or nil
    item_style(item)
  end

  function item:set_text(text)
    local text_w = item._internal.text_w
    if not text_w then return end

    if data.disable_markup then
      text_w:set_text(text)
    else
      text_w:set_markup(text)
    end

--TODO find new largest is item is smaller
--     if data.auto_resize then
--       local fit_w,fit_h = text_w:get_preferred_size()
--       local is_largest = item == data._internal.largest_item_h
--       if not data._internal.largest_item_h_v or data._internal.largest_item_h_v < fit_h then
--         data._internal.largest_item_h =item
--         data._internal.largest_item_h_v = fit_h
--       end
--     end

    item._private_data.text = text
  end

  -- Overlay and underlay
  item.set_infoshapes = set_infoshapes

  item.set_icon = function (_,value)
    local icon_w = item._internal.icon_w

    if not icon_w then return end

    icon_w:set_image(value)
  end

  -- Listen to signals
  item:connect_signal("state::changed",function()
    item:style()

    -- Some item.style need full widget repaint
    if item.style.need_full_repaint then
      --TODO HACK HACK HACK for the repaint, this is really, really stupid
      data._internal.layout:emit_signal("widget::redraw_needed")
      --TODO END HACK
    end
  end)

  -- Add support for long hover and press
  local main_timer,press_timer = nil
  item:connect_signal("mouse::enter",function(_,m,--[[mod,]]geo)
    if not main_timer then
      main_timer = timer{}
      main_timer.timeout = 1.5
      main_timer:connect_signal("timeout",function()
        item._internal._is_long_hover = true
        item:emit_signal("long::hover",item,{},geo)
        data:emit_signal("long::hover",item,{},geo) --TODO mouse::enter should have modifiers
        main_timer:stop()
      end)
    end
    if not main_timer.started then
--       item:connect_signal("mouse::move",test)
      main_timer:start()
    end
  end)
  item:connect_signal("mouse::leave",function()
    if main_timer and main_timer.started then
      main_timer:stop()
--       item:disconnect_signal("mouse::move",test)
    elseif item._internal._is_long_hover then
      item._internal._is_long_hover = nil
      item:emit_signal("long::exit",data,item)
    end
  end)
  item:connect_signal("button::press",function()
    if not press_timer then
      press_timer = timer{}
      press_timer.timeout = 1.5
      press_timer:connect_signal("timeout",function()
        item:emit_signal("long::press",data,item)
--         item:disconnect_signal("mouse::move",test)
        press_timer:stop()
      end)
    end
    if not press_timer.started then
--       item:connect_signal("mouse::move",test)
      press_timer:start()
    end
  end)
  item:connect_signal("button::release",function()
    if press_timer and press_timer.started then
      press_timer:stop()
    end
  end)

  return item
end

return setmetatable(module, { __call = function(_, ...) return new_item(...) end, __index=load_async})
-- kate: space-indent on; indent-width 2; replace-tabs on;
