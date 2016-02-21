local setmetatable = setmetatable
local print,pairs = print,pairs
local unpack=unpack
local util      = require( "awful.util"       )
local button    = require( "awful.button"     )
local checkbox  = require( "radical.widgets.checkbox" )
local wibox     = require( "wibox" )
local common    = require( "radical.common"           )
local item_layout = require("radical.item.layout.icon")

local module = {}

function module:setup_item(data,item,args)
  local text_w = item._internal.text_w

  -- Setup text
  item.set_text = function (_,value)
    if data.disable_markup then
      text_w:set_text(value)
    else
      text_w:set_markup(value)
    end
    if data.auto_resize then
      local fit_w,fit_h = text_w:get_preferred_size()
      local is_largest = item == data._internal.largest_item_h
      --TODO find new largest is item is smaller
      if not data._internal.largest_item_h_v or data._internal.largest_item_h_v < fit_h then
        data._internal.largest_item_h =item
        data._internal.largest_item_h_v = fit_h
      end
    end
  end

  item:set_text(item._private_data.text)

end

--Get preferred item geometry
local function item_fit(data,item,self, content, width, height)
  if not data.visible then return 1,1 end
  local w, h = item._private_data._fit(self,content,width,height) --TODO port to new context API
  return data.item_width or 70, item._private_data.height or h --TODO broken
end

local function new(data)

    -- Define the item layout
    local real_l = wibox.widget.base.make_widget_declarative {
        spacing         = data.spacing                 ,
        item_fit        = item_fit                     ,
        setup_key_hooks = common.setup_key_hooks       ,
        setup_item      = module.setup_item            ,
        layout          = wibox.layout.fixed.horizontal,
    }

    -- Hack fit
    local new_fit
    new_fit = function(self,context,w,h,force_values) --TODO use the context instead of extra argument
        -- Get the original fit, the function need to be replaced to avoir a stack overflow
        real_l.fit = real_l._fit
        local result,r2 = self:get_preferred_size(context, force_values and w, force_values and h)
        real_l.fit = new_fit

        local w,h
        if data.auto_resize and data._internal.largest_item_h then
            w,h = data.rowcount*(data.item_width or data.default_width),data._internal.largest_item_h_v > data.item_height and data._internal.largest_item_h_v or data.item_height
        else
            w,h = data.rowcount*(data.item_width or data.default_width),data.item_height
        end

        data:emit_signal("layout_size",w,h)

        return w,h
    end

    real_l._fit = real_l.fit
    real_l.fit  = new_fit

    return real_l
end

return setmetatable(module, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
