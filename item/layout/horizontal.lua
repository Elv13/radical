local setmetatable = setmetatable
local beautiful    = require( "beautiful"                  )
local wibox        = require( "wibox"                      )
local fkey         = require( "radical.widgets.fkey"       )
local infoshapes   = require( "radical.widgets.infoshapes" )
local util         = require( "awful.util"                 )
local margins2     = require( "radical.margins"            )
local shape        = require( "gears.shape"                )
local surface      = require( "gears.surface"              )
local common       = require( "radical.item.common"        )

local module = {}

-- Create sub_menu arrows
local sub_arrow = nil
function module:setup_sub_menu_arrow(item,data)
  if (item._private_data.sub_menu_f or item._private_data.sub_menu_m) and not data.disable_submenu_icon then
    if not sub_arrow then
      sub_arrow = wibox.widget.imagebox() --TODO, make global
      sub_arrow.fit = function(box, context,w, h)
        return (sub_arrow._private.image and sub_arrow._private.image:get_width() or 0),item.height
      end

      if beautiful.menu_submenu_icon then
        sub_arrow:set_image( beautiful.menu_submenu_icon   )
      else
        local h = data.item_height
        sub_arrow:set_image(surface.load_from_shape(7, h,
          shape.transform(shape.isosceles_triangle) : rotate_at(3.5,h/2,math.pi/2),
          beautiful.menu_fg_normal or beautiful.menu_fg or beautiful.fg_normal
        ))
      end
    end
    return sub_arrow
  end
end

-- Create the actual widget
local function create_item(item,data,args)
    -- F keys
    common.setup_fkey(item,data)

    -- Icon
    local icon = common.setup_icon(item,data)

    local checkbox = common.setup_checked(item,data)

    -- Define the item layout
    item.widget = wibox.widget.base.make_widget_declarative {
        -- Widgets
        {

            -- Widget
            {
                -- This is where the content is placed

                -- Widgets
                {
                    -- The prefixes

                    -- Widget
                    data.fkeys_prefix and fkey(data,item) or nil,
                    {
                        icon                                    ,
                        right  = 3                              ,
                        widget = wibox.container.margin         ,
                    },
                    args.prefix_widget                          ,

                    -- Attributes
                    layout = wibox.layout.fixed.horizontal
                },
                {
                    -- Underlay and overlay
                    {
                        -- The main textbox
                        id            = "main_text"         ,
                        _data         = data                ,
                        _private_data = item._private_data  ,
                        text          = item.text           ,
                        widget        = wibox.widget.textbox,
                    },

                    -- Attributes
                    widget     = infoshapes,
                    spacing    = 10,
                    infoshapes = item.infoshapes,
                    id         = "infoshapes",
                },
                {
                    -- Suffixes

                    -- Widget
                    checkbox                              ,
                    module:setup_sub_menu_arrow(item,data),
                    args.suffix_widget                    ,

                    -- Attributes
                    layout = wibox.layout.fixed.horizontal
                },

                -- Attributes
                _item  = item                         ,
                _data  = data                         ,
                id     = "main_align"                 ,
                layout = wibox.layout.align.horizontal,
            },

            -- Attributes
            id     = "main_margin"      ,
            layout = wibox.container.margin,
        },

        -- Attributes
        fg      = item._private_data.fg  ,
        tooltip = item.tooltip           ,
        _item   = item                   ,
        _data   = data                   ,
        widget  = wibox.container.background,
    }

    -- Make some widgets easier to access
    item._internal.margin_w = item.widget:get_children_by_id("main_margin")[1]
    item._internal.align    = item.widget:get_children_by_id("main_align" )[1]
    item._internal.text_w   = item.widget:get_children_by_id("main_text"  )[1]
    item._internal.icon_w   = icon

    -- Export the margin
    local mrgns = margins2(
        item._internal.margin_w,
        util.table.join(
            (item.item_style or data.item_style).margins,data.default_item_margins
        )
    )

    function item:get_margins()
        return mrgns
    end

    -- Draw
    local item_style = item.style or data.item_style
    item_style(item,{})

    -- Setup events
    common.setup_event(data,item)

    return item.widget
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
