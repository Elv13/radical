local setmetatable = setmetatable
local pairs,ipairs = pairs, ipairs
local type,string  = type,string
local print,unpack = print, unpack
local beautiful    = require( "beautiful"          )
local util         = require( "awful.util"         )
local object       = require( "radical.object"     )
local item_style   = require( "radical.item_style" )

local capi = { mouse = mouse, screen = screen , keygrabber = keygrabber }

local module = {
  arrow_type = {
    NONE     = 0,
    PRETTY   = 1,
    CENTERED = 2,
}}

local function filter(data)
  local fs,visible_counter = data.filter_string:lower(),0
  data._internal.visible_item_count = 0
  for k,v in pairs(data.items) do
    local tmp = v[1]._filter_out
    v[1]._filter_out = (v[1].text:lower():find(fs) == nil)-- or (fs ~= "")
    if tmp ~= v[1]._filter_out then
      v[1].widget:emit_signal("widget::updated")
    end
    if not v[1]._filter_out then
      visible_counter = visible_counter + v[1].height
      data._internal.visible_item_count = data._internal.visible_item_count +1
      v[1].f_key = data._internal.visible_item_count
    end
  end
  data._total_item_height = visible_counter
  local w,h = data._internal.layout:fit()
  data.height = h
end

------------------------------------KEYBOARD HANDLING-----------------------------------
local function activateKeyboard(data)
  if not data then return end
  if not data or grabKeyboard == true then return end
  if (not (data.keyboardnav == false)) and data.visible == true then
    capi.keygrabber.run(function(mod, key, event)
        for k,v in pairs(data._internal.filter_hooks or {}) do --TODO modkeys
            if k.key == "Mod4" and (key == "End" or key == "Super_L") then
                local found = false
                for k3,v3 in ipairs(mod) do
                    if v3 == "Mod4" and event == k.event then
                        local retval,self = v(data,mod)
                        if self and type(self) == "table" then
                          data = self
                        end
                    end
                end
            end
            if k.key == key and k.event == event then
                local retval, self = v(data,mod)
                if self and type(self) == "table" then
                  data = self
                end
                return retval
            end
        end
        if event == "release" then
            return true
        end

        if (key == 'Return') and data._current_item and data._current_item.button1 then
            data._current_item.button1()
            data.visible = false
        elseif key == 'Escape' or (key == 'Tab' and data.filter_string == "") then
            data.visible = false
            capi.keygrabber.stop()
        elseif (key == 'BackSpace') and data.filter_string ~= "" and data.filter == true then
            data.filter_string = data.filter_string:sub(1,-2)
            filter(data)
--             data:filter(data.filter_string:lower())
--             if getFilterWidget() ~= nil then
--               getFilterWidget().textbox:set_markup(getFilterWidget().textbox._layout.text:sub(1,-2))
--             end
        elseif data.filter == true and key:len() == 1 then
            data.filter_string = data.filter_string .. key:lower()
--             local fw = getFilterWidget()
--             if fw ~= nil then
--               fw.textbox:set_markup(fw.textbox._layout.text .. key:lower())
--               if data.settings.autoresize and fw.textbox._layout:get_pixel_extents().width > data.settings.itemWidth then
--                 data.settings.itemWidth = fw.textbox._layout:get_pixel_extents().width + 40
--                 data.hasChanged = true
--                 data:set_coords()
--               end
--             end
            filter(data)
        else
          data.visible = false
          capi.keygrabber.stop()
        end
        return true
    end)
  end
end


---------------------------------ITEM HANDLING----------------------------------
local function add_item(data,args)
  local args = args or {}
  local item,set_map,get_map,private_data = object({
    private_data = {
      text       = args.text     or ""                                                                  ,
      height     = args.height   or beautiful.menu_height or 30                                         ,
      icon       = args.icon     or nil                                                                 ,
      prefix     = args.prefix   or ""                                                                  ,
      suffix     = args.suffix   or ""                                                                  ,
      bg         = args.bg       or nil                                                                 ,
      fg         = args.fg       or data.fg       or beautiful.menu_fg_normal or beautiful.fg_normal,
      fg_focus   = args.fg_focus or data.fg_focus or beautiful.menu_fg_focus  or beautiful.fg_focus ,
      bg_focus   = args.bg_focus or data.bg_focus or beautiful.menu_bg_focus  or beautiful.bg_focus ,
      sub_menu_m = (args.sub_menu and type(args.sub_menu) == "table" and args.sub_menu.is_menu) and args.sub_menu or nil,
      sub_menu_f = (args.sub_menu and type(args.sub_menu) == "function") and args.sub_menu or nil,
      selected   = false,
      checkable  = args.checkable or (args.checked ~= nil) or false,
      checked    = args.checked or false,
      underlay   = args.underlay or nil,
    },
    force_private = {
      visible = true,
      selected = true,
    },
    get_map = {
      y = function() return (args.y and args.y >= 0) and args.y or data.height - (data.margins.top or data.border_width) - data.item_height end, --Hack around missing :fit call for last item
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })
  item._private_data = private_data
  item._internal = {get_map=get_map,set_map=set_map}

  for i=1,10 do
    item["button"..i] = args["button"..i]
  end
  
  if data.max_items ~= nil and data.rowcount >= data.max_items then-- and (data._start_at or 0)
    item._hidden = true
  end

  set_map.selected = function(value)
    private_data.selected = value
    if value == false then
      data.item_style(data,item,false--[[ or (item._tmp_menu ~= nil and item._tmp_menu == data._tmp_menu)]],false)
      return
    end
    if data._current_item and data._current_item ~= item then
      if data._current_item._tmp_menu then
        data._current_item._tmp_menu.visible = false
        data._current_item._tmp_menu = nil
        data._tmp_menu = nil
      end
      data._current_item.selected = false
    end
    if (private_data.sub_menu_f  or private_data.sub_menu_m)and data._current_item ~= item then
      local sub_menu = private_data.sub_menu_m or private_data.sub_menu_f()
      if sub_menu then
        sub_menu.arrow_type = module.arrow_type.NONE
        sub_menu.parent_item = item
        sub_menu.parent_geometry = data
        sub_menu.visible = true
        item._tmp_menu = sub_menu
        data._tmp_menu = sub_menu
      end
    end
    data.item_style(data,item,true,false)
    data._current_item = item
  end

  data._internal.items[#data._internal.items+1] = {}
  data._internal.items[#data._internal.items][1] = item
  data._internal.setup_item(data,item,args)
  if args.selected == true then
    item.selected = true
  end
  data._internal.visible_item_count = (data._internal.visible_item_count or 0) + 1
  item.f_key = data._internal.visible_item_count
  return item
end


local function add_widget(data,widget,args)
  args = args or {}
  data._internal.has_widget = true
  widget._fit = widget.fit
  widget.fit = function(...)
    local w,h = widget._fit(...)
    return args.width or w,args.height or h
  end

  local item,set_map,get_map,private_data = object({
    private_data = {
      widget = widget,
      selected = false,
    },
    force_private = {
      visible = true,
      selected = true,
    },
    get_map = {
      y = function() return (args.y and args.y >= 0) and args.y or data.height - (data.margins.top or data.border_width) - data.item_height end, --Hack around missing :fit call for last item
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })
  item._private_data = private_data
  item._internal = {get_map=get_map,set_map=set_map}
  
  data._internal.widgets[#data._internal.widgets+1] = item
  data._internal.items[#data._internal.items+1] = {item}
  data._internal.layout:add(item)
  if data.visible then
    local fit_w,fit_h = data._internal.layout:fit()
    data.width = fit_w
    data.height = fit_h
  end
end

local function add_embeded_menu(data,menu)
  
end


---------------------------------MENU HANDLING----------------------------------
local function new(args)
  local internal,args = args.internal or {},args or {}
  if not internal.items then internal.items = {} end
  if not internal.widgets then internal.widgets = {} end

  -- All the magic in the universe
  local data,set_map,get_map,private_data = object({
    private_data = {
      -- Default settings
      bg              = args.bg or beautiful.menu_bg_normal or beautiful.bg_normal or "#000000",
      fg              = args.fg or beautiful.menu_fg_normal or beautiful.fg_normal or "#ffffff",
      bg_focus        = args.bg_focus or beautiful.menu_bg_focus or beautiful.bg_focus or "#ffffff",
      fg_forcus       = args.fg_focus or beautiful.menu_fg_focus or beautiful.fg_focus or "#000000",
      border_color    = args.border_color or beautiful.menu_border_color or beautiful.border_color or "#333333",
      border_width    = args.border_width or beautiful.menu_border_width or beautiful.border_width or 3,
      item_height     = args.item_height  or beautiful.menu_height or 30,
      item_width      = args.item_width or nil,
      width           = args.width or beautiful.menu_width or 130,
      default_width   = args.width or beautiful.menu_width or 130,
      icon_size       = args.icon_size or nil,
      auto_resize     = args.auto_resize or true,
      parent_geometry = args.parent or nil,
      arrow_type      = args.arrow_type or beautiful.menu_arrow_type or module.arrow_type.PRETTY,
      visible         = args.visible or false,
      direction       = args.direction or "top",
      has_changed     = false,
      row             = args.row or nil,
      column          = args.column or nil,
      layout          = args.layout or nil,
      screen          = args.screen or nil,
      style           = args.style  or nil,
      item_style      = args.item_style or item_style.basic,
      filter          = args.filter or true,
      show_filter     = args.show_filter or false,
      filter_string   = args.filter_string or "",
      suffix_widget   = args.suffix_widget or nil,
      prefix_widget   = args.prefix_widget or nil,
      fkeys_prefix    = args.fkeys_prefix or false,
      underlay_alpha  = args.underlay_alpha or 0.7,
      filter_prefix   = args.filter_prefix or "Filter:",
      max_items       = args.max_items or nil,
    },
    get_map = {
      is_menu       = function() return true end,
      margin        = function() return {left=0,bottom=0,right=0,left=0} end,
      items         = function() return internal.items end,
      rowcount      = function() return #internal.items end,
      columncount   = function() return (#internal.items > 0) and #(internal.items[1]) or 0  end,
    },
    set_map = {
      auto_resize  = function(val) private_data[""] = val end,
    },
    force_private = {
      parent  = true,
      visible = true,
    },
    always_handle = {
      width = true,
      height = true,
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })
  internal.get_map,internal.set_map,internal.private_data = get_map,set_map,private_data
  data.add_item,data.add_widget,data.add_embeded_menu,data._internal = add_item,add_widget,add_embeded_menu,internal

  set_map.parent_geometry = function(value)
    private_data.parent_geometry = value
    if data._internal.get_direction then
      data.direction = data._internal.get_direction(data)
    end
    if data._internal.set_position then
      data._internal.set_position(data)
    end
  end

  set_map.visible = function(value)
    private_data.visible = value
    if value then
      local fit_w,fit_h = data._internal.layout:fit()
      data.width = fit_w
      data.height = fit_h
    end
    if internal.has_changed and data.style then
      data.style(data,{arrow_x=20,margin=internal.margin})
    end
    if not internal.parent_geometry and data._internal.set_position then
      internal.set_position(data)
    end
    if internal.set_visible then
      internal:set_visible(value)
    end
    if value and not capi.keygrabber.isrunning() then
      activateKeyboard(data)
    elseif data.parent_geometry and not data.parent_geometry.is_menu then
      capi.keygrabber.stop()
    end
  end
  
  set_map.layout = function(value)
    if value then
      value:setup_key_hooks(data)
    end
    private_data.layout = value
  end

--   set_map.auto_resize = function(value)
--     for k,v in ipairs(internal.items) do
--       TODO check all items size, ajustthe fit and global width
--     end
--   end

  get_map.current_index = function()
    if data._current_item then
      for k,v in ipairs(internal.items) do --rows
        for k2,v2 in ipairs(v) do --columns
          if data._current_item == v2 then
            return k,k2 --row, column as row is expected in most configurations
          end
        end
      end
    end
  end

  get_map.previous_item = function() return (internal.items[(data.current_index or 0)-1] or internal.items[data.rowcount])[1] end
  get_map.next_item     = function() return ((internal.items[(data.current_index or 0)+1]or{})[1] or internal.items[1][1]) end

  --Repaint when appearance properties change
  for k,v in ipairs({"bg","fg","border_color","border_width","item_height","width","arrow_type"}) do
    data:connect_signal(v.."::changed",function()
      if data.visible and data.style then
--         data.style(data,{arrow_x=20,margin=internal.margin})
      else
        data.has_changed = true
      end
    end)
  end

  function data:add_key_hook(mod, key, event, func)
    if key and event and func then
        internal.filter_hooks = internal.filter_hooks or {}
        internal.filter_hooks[{key = key, event = event, mod = mod}] = func
    end
  end

  function data:remove_key_hook(key)
      for k,v in pairs(internal.filter_hooks) do
          if k.key == key then
              internal.filter_hooks[k] = nil
              break
          end
      end
  end

  function data:clear()
    internal.items = {}
    data:emit_signal("clear::menu")
  end

  function data:scroll_up()
    if data.max_items ~= nil and data.rowcount >= data.max_items and (data._start_at or 1) > 1 then
      data._start_at  = (data._start_at or 1) - 1
      internal.items[data._start_at][1]._hidden = false
      data:emit_signal("_hidden::changed",internal.items[data._start_at][1])
      internal.items[data._start_at+data.max_items][1]._hidden = true
      data:emit_signal("_hidden::changed",internal.items[data._start_at+data.max_items][1])
    end
  end
  
  function data:scroll_down()
    if data.max_items ~= nil and data.rowcount >= data.max_items and (data._start_at or 1)+data.max_items <= data.rowcount then
      data._start_at  = (data._start_at or 1) + 1
      internal.items[data._start_at-1][1]._hidden = true
      data:emit_signal("_hidden::changed",internal.items[data._start_at-1][1])
      internal.items[data._start_at-1+data.max_items][1]._hidden = false
      data:emit_signal("_hidden::changed",internal.items[data._start_at-1+data.max_items][1])
    end
  end

  if private_data.layout then
    private_data.layout:setup_key_hooks(data)
  end

  data._internal.setup_drawable(data)

  return data
end
return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
