local wibox = require("wibox")
local beautiful = require("beautiful")
local color = require("gears.color")
local ipairs = ipairs
local print = print

local function textbox_draw(self, context, cr, width, height)
  cr:save()
  cr:set_source(color(beautiful.menu_border_color or beautiful.border_normal or beautiful.border_color))
  cr:rectangle(0,0,width,1)
  cr:rectangle(width-1,0,1,height)
  cr:stroke()
  cr:restore()
  cr:set_source(color(beautiful.menu_fg_normal or beautiful.fg_normal))
  wibox.widget.textbox.draw(self, context, cr, width, height)
end

local function create_textbox(context,col_c,col,has_v_header,row_height)
  local t = wibox.widget.textbox()

  t.fit = function(s,context,w2,h)
    local fw,fh = wibox.widget.textbox.fit(s,context,w2,h)
    return (w2/(col_c+2 - col)),row_height or fh
  end
  t.draw = textbox_draw
  t:set_align("center")
  return t
end

local function create_h_header(main_l,cols,context,args)
  if args.h_header then
    local bg = wibox.widget.background()
    local row_l = wibox.layout.fixed.horizontal()
    bg:set_bg(beautiful.menu_table_bg_header or beautiful.menu_bg_header or beautiful.fg_normal)
    bg:set_widget(row_l)
    if args.v_header then
      local t = create_textbox(context,cols,1,args.v_header ~= nil,args.row_height)
      t:set_markup("<span color='".. beautiful.bg_normal .."'>--</span>")
      row_l:add(t)
    end
    for i=1,cols do
      local t = create_textbox(context,cols,i+1,args.v_header ~= nil,args.row_height)
      t:set_markup("<span color='".. beautiful.bg_normal .."'>".. (args.h_header[i] or "-") .."</span>")
      row_l:add(t)
    end
    main_l:add(bg)
  end
end

local function new(content,args)
  local args = args or {}
  local rows = #content
  local cols = 0
  for k,v in ipairs(content) do
    if #v > cols then
      cols = #v
    end
  end
  local main_l = wibox.layout.fixed.vertical()
  local w =200
  main_l.fit = function(self,context,width,height)
    w = width
    return wibox.layout.fixed.fit(self,context,width,height)
  end
  create_h_header(main_l,cols,w,args)

  local j,widgets =1,{}
  for k,v in  ipairs(content) do
    local row_l,row_w = wibox.layout.fixed.horizontal(),{}
    if args.v_header then
      local t = create_textbox(w,cols,1,args.v_header ~= nil,args.row_height)
      t:set_markup("<span color='".. beautiful.bg_normal .."'>".. (args.v_header[j] or "-") .."</span>")
      local bg = wibox.widget.background()
      bg:set_bg(beautiful.menu_table_bg_header or beautiful.menu_bg_header or beautiful.fg_normal)
      bg:set_widget(t)
      row_l:add(bg)
    end
    for i=1,cols do
      local t = create_textbox(w,cols,i+1,args.v_header ~= nil,args.row_height)
      t:set_text(v[i])
      row_l:add(t)
      row_w[#row_w+1] =t
    end
    main_l:add(row_l)
    widgets[#widgets+1] = row_w
    j = j +1
  end
  return main_l,widgets
end

return setmetatable({}, { __call = function(_, ...) return new(...) end })
-- kate: space-indent on; indent-width 2; replace-tabs on;
