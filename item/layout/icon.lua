local setmetatable = setmetatable
local beautiful  = require( "beautiful"    )
local color      = require( "gears.color"  )
local cairo      = require( "lgi"          ).cairo
local wibox      = require( "wibox"        )
local checkbox   = require( "radical.widgets.checkbox" )
local fkey       = require( "radical.widgets.fkey"         )
local horizontal = require( "radical.item.layout.horizontal" )
local util       = require( "awful.util"                )
local margins2   = require("radical.margins")

local module = {}

local function icon_fit(data,...)
  local w,h = wibox.widget.imagebox.fit(...)
  --Try to retermine the limiting factor
  if data._internal.layout.dir == "y" then
    return data.icon_size or w,data.icon_size or h
  else
    return w,data.icon_size or h
  end
  
end

local function icon_draw(self, context, cr, width, height)
  local w,h = wibox.widget.imagebox.fit(self,context,width,height)
  cr:save()
  cr:translate((width-w)/2,0)
  wibox.widget.imagebox.draw(self, context, cr, width, height)
  cr:restore()
end

local function create_item(item,data,args)
  --Create the background
  local bg = wibox.widget.background()
  bg:set_fg(item._private_data.fg)

  --Create the main item layout
  local l,la,lr = wibox.layout.fixed.vertical(),wibox.layout.align.vertical(),wibox.layout.fixed.horizontal()
  local m = wibox.layout.margin(la)
  local mrgns = margins2(m,util.table.join(data.item_style.margins,data.default_item_margins))
  item.get_margins = function()
    return mrgns
  end

  local text_w = wibox.widget.textbox()
  text_w:set_align("center")
  item._private_data._fit = wibox.widget.background.fit
--   m.fit = function(...)
--       if item.visible == false or item._filter_out == true then
--         return 0,0
--       end
--       local w,h = data._internal.layout.item_fit(data,item,...)
--       print("item_fit",w,h)
--       return data._internal.layout.item_fit(data,item,...)
--   end

  if data.fkeys_prefix == true then
    local pref = wibox.widget.textbox()
    pref.draw = function(self, context, cr, width, height)
      cr:set_source(color(beautiful.fg_normal))
      cr:paint()
      wibox.widget.textbox.draw(self, context, cr, width, height)
    end
    l:add(pref)
    m:set_left  ( 0 )
  end

  if args.prefix_widget then
    l:add(args.prefix_widget)
  end

  local icon = horizontal.setup_icon(horizontal,item,data)
  icon.fit = function(...) return icon_fit(data,...) end
  icon.draw = icon_draw

  l:add(icon)
  l:add(text_w)
  if item._private_data.sub_menu_f or item._private_data.sub_menu_m then
    local subArrow  = wibox.widget.imagebox() --TODO, make global
    subArrow.fit = function(box, context, w, h) return subArrow._image:get_width(),item.height end
    subArrow:set_image( beautiful.menu_submenu_icon   )
    lr:add(subArrow)
  end
  bg.fit = function(box, context, w,h)
--     args.y = data.height-h-data.margins.top --TODO dead code?
    if data._internal.layout.item_fit then
      return data._internal.layout.item_fit(data,item,box,context, w, h)
    else
      return wibox.widget.background.fit(box,context, w,h)
    end
    return 0,0
  end
  if item.checkable then
    item.get_checked = function(data,item)
      if type(item._private_data.checked) == "function" then
        return item._private_data.checked()
      else
        return item._private_data.checked
      end
    end
    local ck = wibox.widget.imagebox()
    ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    lr:add(ck)
    item.set_checked = function (_,value)
      item._private_data.checked = value
      ck:set_image(item.checked and checkbox.checked() or checkbox.unchecked())
    end
  end
  if args.suffix_widget then
    lr:add(args.suffix_widget)
  end
  la:set_top(l)
  la:set_bottom(lr)
  bg:set_widget(m)

  item._internal.text_w = text_w
  item._internal.icon_w = icon

  -- Setup events
  horizontal.setup_event(data,item,bg)
  
  item.widget = bg

  return bg
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
