local setmetatable = setmetatable
local pairs,ipairs = pairs, ipairs
local type,string  = type,string
local print,unpack = print, unpack
local table        = table
local beautiful    = require( "beautiful"               )
local util         = require( "awful.util"              )
local aw_key       = require( "awful.key"               )
local object       = require( "radical.object"          )
local vertical     = require( "radical.layout.vertical" )
local theme        = require( "radical.theme"           )
local item_mod     = require( "radical.item"            )

local capi = { mouse = mouse, screen = screen , keygrabber = keygrabber, root=root, }

local module = {
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
    PRESSED   = 4 , -- Mouse pressed
    HOVERED   = -1 , -- Mouse hover
    CHANGED   = 6 , -- The item changed, need attention
    USED      = 7 , -- Common flag
    CHECKED   = 8 , -- When checkbox isn't enough
    ALTERNATE = 9 ,
    HIGHLIGHT = 10 ,
    HEADER    = 11,

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
  colors_by_id = theme.colors_by_id
}

theme.register_color(module.item_flags.DISABLED  , "disabled"  , "disabled"  , true )
theme.register_color(module.item_flags.URGENT    , "urgent"    , "urgent"    , true )
theme.register_color(module.item_flags.SELECTED  , "focus"     , "focus"     , true )
theme.register_color(module.item_flags.PRESSED   , "pressed"   , "pressed"   , true )
theme.register_color(module.item_flags.HOVERED   , "hover"     , "hover"     , true )
theme.register_color(module.item_flags.CHANGED   , "changed"   , "changed"   , true )
theme.register_color(module.item_flags.USED      , "used"      , "used"      , true )
theme.register_color(module.item_flags.CHECKED   , "checked"   , "checked"   , true )
theme.register_color(module.item_flags.ALTERNATE , "alternate" , "alternate" , true )
theme.register_color(module.item_flags.HIGHLIGHT , "highlight" , "highlight" , true )
--     register_color(item_flags.HEADER    , ""
--     register_color(item_flags.USR1      , ""
--     register_color(item_flags.USR2      , ""
--     register_color(item_flags.USR3      , ""
--     register_color(item_flags.USR4      , ""
--     register_color(item_flags.USR5      , ""
--     register_color(item_flags.USR6      , ""
--     register_color(item_flags.USR7      , ""
--     register_color(item_flags.USR8      , ""
--     register_color(item_flags.USR9      , ""
--     register_color(item_flags.USR10     , ""


local function filter(data)
  if not data.filter == false then
    local fs,visible_counter = data.filter_string:lower(),0
    data._internal.visible_item_count = 0
    for k,v in pairs(data.items) do
      local tmp = v._filter_out
      v._filter_out = (v.text:lower():find(fs) == nil)-- or (fs ~= "")
      if tmp ~= v._filter_out then
        v.widget:emit_signal("widget::updated")
      end
      if (not v._filter_out) and (not v._hidden) then
        visible_counter = visible_counter + v.height
        data._internal.visible_item_count = data._internal.visible_item_count +1
        v.f_key = data._internal.visible_item_count
      end
    end
    data._total_item_height = visible_counter
    local w,h = data._internal.layout:fit()
    data.height = h
  end
end

------------------------------------KEYBOARD HANDLING-----------------------------------
local function activateKeyboard(data)
  if not data then return end
  if not data or grabKeyboard == true then return end
  if (not (data._internal.private_data.enable_keyboard == false)) and data.visible == true then
    capi.keygrabber.run(function(mod, key, event)
      for k,v in pairs(data._internal.filter_hooks or {}) do --TODO modkeys
        if (k.key == "Mod4" or k.key == "Mod1") and (key == "End" or key == "Super_L" or key == "Alt_L") then
          local found = false
          for k3,v3 in ipairs(mod) do
            for k4,v4 in ipairs({"Mod4","Mod1"})do
              if v3 == v4 and event == k.event then
                local retval,self = v(data,mod)
                if self and type(self) == "table" then
                  data = self
                end
              end
            end
          end
        end
        if k.key == key and k.event == event then
          local retval, self = v(data,mod)
          if self and type(self) == "table" then
            data = self
          end
          if retval == false then
            data.visible = false
            capi.keygrabber.stop()
          end
          return retval
        end
      end
      if event == "release" then
          return true
      end

      if (key == 'Return') and data._current_item and data._current_item.button1 then
        if data.sub_menu_on == module.event.BUTTON1 then
          item_mod.execute_sub_menu(data,data._current_item)
        else
          data._current_item.button1(data,data._current_item)
          data.visible = false
        end
      elseif key == 'Escape' or (key == 'Tab' and data.filter_string == "") then
        data.visible = false
        capi.keygrabber.stop()
      elseif (key == 'BackSpace') and data.filter_string ~= "" and data.filter == true then
        data.filter_string = data.filter_string:sub(1,-2)
        filter(data)
      elseif data.filter == true and key:len() == 1 then
        data.filter_string = data.filter_string .. key:lower()
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
  local item = item_mod(data,args)
  data._internal.setup_item(data,item,args)
  if args.selected == true then
    item.selected = true
  end
  item.index = data.rowcount
  data:emit_signal("item::added",item)
  return item
end


local function add_widget(data,widget,args)
  args = args or {}
  data._internal.has_widget = true
  widget._fit = widget.fit
  widget.fit = function(self,width,height)
    local w,h = widget._fit(self,width or 1, height or 1)
    return args.width or w,args.height or h
  end

  local item,private_data = object({
    private_data = {
      widget = widget,
      selected = false,
    },
    force_private = {
      visible = true,
      selected = true,
    },
    autogen_getmap  = true,
    autogen_setmap  = true,
    autogen_signals = true,
  })
  item._private_data = private_data
  item._internal = {}
  item.get_y = function() return (args.y and args.y >= 0) and args.y or data.height - (data.margins.top or data.border_width) - data.item_height end --Hack around missing :fit call for last item

  data._internal.widgets[#data._internal.widgets+1] = item
  data._internal.items[#data._internal.items+1] = item
  data:emit_signal("widget::added",item,widget)
  if data.visible then
    local fit_w,fit_h = data._internal.layout:fit(9999,9999)
    data.width = data._internal.width or fit_w
    data.height = fit_h
  end
end

local function add_prefix_widget(data,widget,args)
  data:emit_signal("prefix_widget::added",widget,args)
end

local function add_suffix_widget(data,widget,args)
  data:emit_signal("suffix_widget::added",widget,args)
end

local function add_embeded_menu(data,menu)
  add_widget(data,menu._internal.layout)
  menu._embeded_parent = data
end

local function add_key_binding(data,mod,key,func)
  capi.root.keys(util.table.join(capi.root.keys(),aw_key(mod or {}, key, func and func() or function ()
      print("bob")
      data.visible = not data.visible
  end)))
end


---------------------------------MENU HANDLING----------------------------------
local function new(args)
  local internal,args = args.internal or {},args or {}
  if not internal.items then internal.items = {} end
  if not internal.widgets then internal.widgets = {} end

  -- All the magic in the universe
  local data,private_data = object({
    private_data = {
      -- Default settings
      bg              = args.bg or beautiful.menu_bg_normal or beautiful.bg_normal or "#000000",
      fg              = args.fg or beautiful.menu_fg_normal or beautiful.fg_normal or "#ffffff",
--       bg_focus        = args.bg_focus or beautiful.menu_bg_focus or beautiful.bg_focus or "#ffffff",
--       fg_focus        = args.fg_focus or beautiful.menu_fg_focus or beautiful.fg_focus or "#000000",
--       bg_alternate    = args.bg_alternate or beautiful.menu_bg_alternate or beautiful.bg_alternate or beautiful.bg_normal,
--       bg_highlight    = args.bg_highlight or beautiful.menu_bg_highlight or beautiful.bg_highlight or beautiful.bg_normal,
      bg_header       = args.bg_header    or beautiful.menu_bg_header or beautiful.fg_normal,
      bg_prefix       = args.bg_prefix    or nil,
--       bg_hover        = args.bg_hover     or nil,
--       fg_hover        = args.fg_hover     or nil,
      border_color    = args.border_color or beautiful.menu_border_color or beautiful.border_color or "#333333",
      border_width    = args.border_width or beautiful.menu_border_width or beautiful.border_width or 3,
      separator_color = args.separator_color or beautiful.menu_separator_color or args.border_color or beautiful.menu_border_color or beautiful.border_color or "#333333",
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
      item_style      = args.item_style or require("radical.item.style.basic"),
      filter          = args.filter ~= false,
      show_filter     = args.show_filter or false,
      filter_string   = args.filter_string or "",
      suffix_widget   = args.suffix_widget or nil,
      prefix_widget   = args.prefix_widget or nil,
      fkeys_prefix    = args.fkeys_prefix or false,
      underlay_alpha  = args.underlay_alpha or beautiful.underlay_alpha  or 0.7,
      underlay_style  = args.underlay_style or nil,
      filter_underlay = args.filter_underlay or nil,
      filter_prefix   = args.filter_prefix or "Filter:",
      enable_keyboard = (args.enable_keyboard ~= false),
      max_items       = args.max_items or nil,
      disable_markup  = args.disable_markup or false,
      x               = args.x or 0,
      y               = args.y or 0,
      sub_menu_on     = args.sub_menu_on or module.event.SELECTED,
      select_on       = args.select_on or module.event.HOVER,
      overlay         = args.overlay or nil,
      opacity         = args.opacity or beautiful.menu_opacity or 1,
      icon_transformation = args.icon_transformation or nil,
      filter_underlay_style = args.filter_underlay_style or nil,
      filter_underlay_color = args.filter_underlay_color,
      filter_placeholder    = args.filter_placeholder or "",
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
  internal.private_data = private_data
  data.add_item,data.add_widget,data.add_embeded_menu,data._internal,data.add_key_binding = add_item,add_widget,add_embeded_menu,internal,add_key_binding
  data.add_prefix_widget,data.add_suffix_widget=add_prefix_widget,add_suffix_widget
  theme.setup_colors(data,args)

  -- Getters
  data.get_is_menu       = function(_) return true end
  data.get_margin        = function(_) return {left=0,bottom=0,right=0,left=0} end
  data.get_items         = function(_) return internal.items end
  data.get_rowcount      = function(_) return #internal.items end

  -- Setters
  data.set_auto_resize  = function(_,val) private_data[""] = val end
  data.set_parent_geometry = function(_,value)
    private_data.parent_geometry = value
    if data._internal.get_direction then
      data.direction = data._internal.get_direction(data)
    end
    if data._internal.set_position then
      data._internal.set_position(data)
    end
  end

  data.set_visible = function(_,value)
    private_data.visible = value
    if value then
      local fit_w,fit_h = data._internal.layout:fit(9999,9999)
      data.width = internal.width or fit_w
      data.height = fit_h
    elseif data._tmp_menu and data._current_item then
--       data._tmp_menu = nil
      data._current_item._tmp_menu = nil
--       data._current_item.selected = false
      data.item_style(data._current_item,{})
    end
    if internal.has_changed and data.style then
      data.style(data,{arrow_x=20,margin=internal.margin})
    end
--     if not internal.parent_geometry and data._internal.set_position then
      internal.set_position(data)
--     end
    if internal.set_visible then
      internal:set_visible(value)
    end
    if value and not capi.keygrabber.isrunning() then
      activateKeyboard(data)
    elseif data.parent_geometry and not data.parent_geometry.is_menu and data.enable_keyboard then
      capi.keygrabber.stop()
    end
  end

  data.set_layout = function(_,value)
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

  data.get_current_index = function(_)
    if data._current_item then
      for k,v in ipairs(internal.items) do --rows
        if data._current_item == v then
          return k
        end
      end
    end
  end

  data.get_previous_item = function(_)
    local candidate,idx = internal.items[(data.current_index or 0)-1],(data.current_index or 0)-1
    while candidate and (candidate._hidden or candidate._filter_out) and idx > 0 do
      candidate,idx = internal.items[idx - 1],idx-1
    end
    return (candidate or internal.items[data.rowcount])
  end
  data.get_next_item     = function(_)
    local candidate,idx = internal.items[(data.current_index or 0)+1],(data.current_index or 0)+1
    while candidate and (candidate._hidden or candidate._filter_out) and idx <= data.rowcount do
      candidate,idx = internal.items[idx + 1],idx+1
    end
    return (candidate or internal.items[1])
  end

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

  function data:remove_key_hook(key) --TODO broken?
      for k,v in pairs(internal.filter_hooks or {}) do
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

  function data:swap(item1,item2)
    if not item1 or not item2 then return end
    if not item1 or not item2 and item1 ~= item2 then return end
    local idx1,idx2
    for k,v in ipairs(internal.items) do --rows
      for k2,v2 in ipairs(v) do --columns
        if item2 == v2 then
          idx2 = k
        end
        if item1 == v2 then
          idx1 = k
        end
      end
      if idx1 and idx2 then
        break
      end
    end
    if idx1 and idx2 then
      internal.items[idx1],internal.items[idx2] = internal.items[idx2],internal.items[idx1]
      item1.index,item2.index = idx2,idx1
      data:emit_signal("item::swapped",item1,item2,idx1,idx2)
    end
  end

  function data:move(item,idx)
    if not item or not idx then return end
    local idx1 = nil
    for k,v in ipairs(internal.items) do --rows
      if item == v then
        idx1 = k
        break
      end
    end
    if idx1 then
--       if idx < idx1 then
--         idx = idx + 1
--       end
      if idx1 > #internal.items + 1 then
        idx1 = #internal.items + 1
      end
      if idx ~= idx1 then
        table.insert(internal.items,idx1,table.remove(internal.items,idx))
        item.index = idx
        data:emit_signal("item::moved",item,idx,idx1)
        for i=idx,idx1 do
          internal.items[i].index = i
        end
      end
    end
  end

  function data:remove(item)
    if not item then return end
    local idx1 = nil
    for k,v in ipairs(internal.items) do --rows
      if item == v then
        idx1 = k
        break
      end
    end
    if idx1 then
      table.remove(internal.items,idx1)
      data:emit_signal("item::removed",item,idx1)
      for i=idx1,#internal.items do
        internal.items[i].index = i
      end
    end
  end

  function data:append(item)
    if not item then return end
    internal.items[#internal.items + 1] = item
    data:emit_signal("item::appended",item)
  end

  function data:scroll_up()
    if data.max_items ~= nil and data.rowcount >= data.max_items and (data._start_at or 1) > 1 then
      local current_item = data._current_item
      if current_item then
        current_item:set_selected(false,true)
      end
      data._start_at  = (data._start_at or 1) - 1
      internal.items[data._start_at]._hidden = false
      data:emit_signal("_hidden::changed",internal.items[data._start_at])
      internal.items[data._start_at+data.max_items]._hidden = true
      data:emit_signal("_hidden::changed",internal.items[data._start_at+data.max_items])
      filter(data)
    end
  end

  function data:scroll_down()
    if data.max_items ~= nil and data.rowcount >= data.max_items and (data._start_at or 1)+data.max_items <= data.rowcount then
      local current_item = data._current_item
      if current_item then
        current_item:set_selected(false,true)
      end
      data._start_at  = (data._start_at or 1) + 1
      internal.items[data._start_at-1]._hidden = true
      data:emit_signal("_hidden::changed",internal.items[data._start_at-1])
      internal.items[data._start_at-1+data.max_items]._hidden = false
      data:emit_signal("_hidden::changed",internal.items[data._start_at-1+data.max_items])
      filter(data)
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
