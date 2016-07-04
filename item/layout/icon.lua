local setmetatable = setmetatable
local beautiful    = require( "beautiful"                      )
local color        = require( "gears.color"                    )
local wibox        = require( "wibox"                          )
local util         = require( "awful.util"                     )
local margins2     = require( "radical.margins"                )
local common       = require( "radical.item.common"            )

local module = {}

local function after_draw_children(self, context, cr, width, height)
    wibox.container.background.after_draw_children(self, context, cr, width, height)
    --TODO get rid of this, use the stack container
    if self._item.overlay_draw then
        self._item.overlay_draw(context,self._item,cr,width,height)
    end
end

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
    local w = wibox.widget.imagebox.fit(self,context,width,height)
    cr:save()
    cr:translate((width-w)/2,0)
    wibox.widget.imagebox.draw(self, context, cr, width, height)
    cr:restore()
end

local function create_item(item,data,args)
    local pref, subArrow = nil, nil

    if data.fkeys_prefix == true then
        pref = wibox.widget.textbox()

        function pref:draw(context, cr, width, height)
            cr:set_source(color(beautiful.fg_normal))
            cr:paint()
            wibox.widget.textbox.draw(self, context, cr, width, height)
        end
    end

    local icon = common.setup_icon(item,data)
    icon.fit   = function(...) return icon_fit(data,...) end
    icon.draw  = icon_draw --TODO use a constraint

    local checkbox = common.setup_checked(item,data)

    local has_children = item._private_data.sub_menu_f or item._private_data.sub_menu_m

    if has_children then
        subArrow  = wibox.widget.imagebox() --TODO, make global

        function subArrow:fit(context, w, h)
            return subArrow._image:get_width(),item.height
        end

        subArrow:set_image( beautiful.menu_submenu_icon   )
    end

    local function bg_fit(box, context, w,h)
        if data._internal.layout.item_fit then
            return data._internal.layout.item_fit(data,item,box,context, w, h)
        else
            return wibox.container.background.fit(box,context, w,h)
        end
    end

    local w = wibox.widget.base.make_widget_declarative {
        {
            {
                {
                    pref or nil,
                    args.prefix_widget               ,
                    icon,
                    {
                        align  = "center"            ,
                        id     = "main_text"         ,
                        widget = wibox.widget.textbox,
                    },
                    layout = wibox.layout.fixed.vertical,
                },
                nil, -- Center
                {
                    -- Suffix

                    -- Widgets
                    subArrow or nil    ,
                    checkbox or nil    ,
                    args.suffix_widget                    ,

                    -- Attributes
                    layout = wibox.layout.fixed.horizontal,
                },
                layout = wibox.layout.align.vertical
            },
            left   = data.fkeys_prefix and 0 or nil,
            id     = "main_margin",
            layout = wibox.container.margin,
        },

        -- Attributes
        fg     = item._private_data.fg,
        _item  = item,
        widget = wibox.container.background
    }

    item.widget             = w
    item._internal.icon_w   = icon
    item._internal.margin_w = item.widget:get_children_by_id("main_margin")[1]
    item._internal.text_w   = item.widget:get_children_by_id("main_text")[1]
    item._private_data._fit = wibox.container.background.fit
    w.after_draw_children   = after_draw_children
    w.fit                   = bg_fit

    -- Setup margins
    local mrgns = margins2(
        item._internal.margin_w,
        util.table.join(data.item_style.margins,data.default_item_margins)
    )

    function item:get_margins()
        return mrgns
    end

    -- Setup events
    common.setup_event(data,item,w)

    return w
end

return setmetatable(module, { __call = function(_, ...) return create_item(...) end })
-- kate: space-indent on; indent-width 4; replace-tabs on;
