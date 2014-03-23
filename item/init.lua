local type = type
local beautiful = require("beautiful")
local theme = require("radical.theme")
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
  end
  return rawget(module,key)
end

function module.execute_sub_menu(data,item)
  if (item._private_data.sub_menu_f  or item._private_data.sub_menu_m) then
    local sub_menu = item._private_data.sub_menu_m or item._private_data.sub_menu_f(data,item)
    if sub_menu and (item._private_data.sub_menu_f or sub_menu.rowcount > 0) then
      sub_menu.arrow_type = module.arrow_type.NONE
      sub_menu.parent_item = item
      sub_menu.parent_geometry = data
      sub_menu.visible = true
      item._tmp_menu = sub_menu
      data._tmp_menu = sub_menu
    end
  end
end

local function new_item(data,args)
  local args = args or {}
  local item,private_data = object({
    private_data  = {
      text        = args.text        or ""                                                                  ,
      height      = args.height      or data.item_height or beautiful.menu_height or 30                     ,
      width       = args.width       or nil                                                                 ,
      icon        = args.icon        or nil                                                                 ,
      prefix      = args.prefix      or ""                                                                  ,
      suffix      = args.suffix      or ""                                                                  ,
      bg          = args.bg          or nil                                                                 ,
      fg          = args.fg          or data.fg                                                             , --TODO don't do this
      border_color= args.border_color or data.border_color                                                  ,
      bg_prefix   = args.bg_prefix   or data.bg_prefix                                                      ,
      sub_menu_m  = (args.sub_menu   and type(args.sub_menu) == "table" and args.sub_menu.is_menu) and args.sub_menu or nil,
      sub_menu_f  = (args.sub_menu   and type(args.sub_menu) == "function") and args.sub_menu or nil        ,
      checkable   = args.checkable   or (args.checked ~= nil) or false                                      ,
      checked     = args.checked     or false                                                               ,
      underlay    = args.underlay    or nil                                                                 ,
      tooltip     = args.tooltip     or nil                                                                 ,
      style       = args.style       or data.item_style                                                     ,
      item_layout = args.item_layout or nil                                                                 ,
      overlay     = args.overlay     or data.overlay or nil                                                 ,
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
  item._internal     = {}
  theme.setup_item_colors(data,item,args)
  item.get_y = function() return (args.y and args.y >= 0) and args.y or data.height - (data.margins.top or data.border_width) - data.item_height end --Hack around missing :fit call for last item
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

  if data.max_items ~= nil and data.rowcount >= data.max_items then-- and (data._start_at or 0)
    item._hidden = true
  end

  -- Use _internal to avoid the radical.object trigger
  data._internal.visible_item_count = (data._internal.visible_item_count or 0) + 1
  item._internal.f_key = data._internal.visible_item_count

  -- Need to be done before painting
  data._internal.items[#data._internal.items+1] = {}
  data._internal.items[#data._internal.items] = item

  -- Getters
  item.get_selected = function(_)
    return item == data._current_item
  end

  -- Setters
  item.set_selected = function(_,value,force)
    private_data.selected = value

    -- Hide the sub-menu
    local current_item = data._current_item
    if current_item and current_item ~= item or force then
      current_item.state[module.item_flags.SELECTED] = nil
      if current_item._tmp_menu then
        current_item._tmp_menu.visible = false
        current_item._tmp_menu = nil
        data._tmp_menu = nil
        current_item:emit_signal("state::changed")
      end
    end

    -- Unselect item
    if value == false then
      item.state[module.item_flags.SELECTED] = nil
      return
    end

    -- Select the new one
    if data.sub_menu_on == module.event.SELECTED and current_item ~= item then
      module.execute_sub_menu(data,item)
    end
    item.state[module.item_flags.SELECTED] = true
    data._current_item = item
  end

  -- Listen to signals
  item:connect_signal("state::changed",function()
    item:style()
  end)

  return item
end

return setmetatable(module, { __call = function(_, ...) return new_item(...) end, __index=load_async})
-- kate: space-indent on; indent-width 2; replace-tabs on;