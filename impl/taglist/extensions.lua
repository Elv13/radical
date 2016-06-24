-- This file provide extensions 

local capi = { screen = screen, client=client}
local ipairs,pairs = ipairs,pairs
local radical   = require( "radical"    )
local taglist = nil

local module = {}

local current_client = nil
local current_pos = nil

local classes = {}
local global = {}

local extension_list = {}

local function read_add(item,w,position)
  if position == "suffix" then
    item:add_suffix(w)
  elseif position == "prefix" then
    item:add_prefix(w)
  elseif position == "overlay" then
    item:add_overlay(w)
  end
end

local per_m,per_glob,per_this = nil
local function persistence_menu(ext,position)
  if not taglist then
    taglist = require("radical.impl.taglist")
  end
  if not per_m then
    per_m = radical.context{}
    per_glob  = per_m:add_item{text= "All clients"      ,checkable = true , button1 = function()
      local i1 = taglist.item(current_client)
      if i1 and (not i1._internal.has_widget or not i1._internal.has_widget[ext]) then
        read_add(i1,ext(current_client),current_pos)
        i1._internal.has_widget = i1._internal.has_widget or {}
        i1._internal.has_widget[ext] = true
      end
      for k,v in ipairs(capi.client.get()) do
        local i2 = taglist.item(v)
        if i2 and  (not i2._internal.has_widget or not i2._internal.has_widget[ext]) then
          read_add(i2,ext(v),current_pos)
          i2._internal.has_widget = i2._internal.has_widget or {}
          i2._internal.has_widget[ext] = true
        end
      end
      per_glob.checked = true
    end}
    per_this  = per_m:add_item{text= "This client only" ,checkable = true, button1 = function()
      local i1 = taglist.item(current_client)
      if i1 and (not i1._internal.has_widget or not i1._internal.has_widget[ext]) then
        read_add(i1,ext(current_client),current_pos)
        i1._internal.has_widget = i1._internal.has_widget or {}
        i1._internal.has_widget[ext] = true
      end
      per_this.checked = true
    end}
  end

  -- Check the checkboxes
  local i1 = taglist.item(current_client)
  if global[ext] then
    per_glob.checked  = true
    per_this.checked  = false
  elseif classes[ext] and classes[ext][current_client.class] then
    per_this.checked  = false
    per_glob.checked  = false
  elseif i1 and i1._internal.has_widget and i1._internal.has_widget[ext] then
    per_this.checked  = true
    per_glob.checked  = false
  else
    per_this.checked  = false
    per_glob.checked  = false
  end

  return per_m
end

local ext_list_m = nil
local function extension_list_menu(position)
  current_pos = position
  if not ext_list_m then
    ext_list_m = radical.context{}
    for k,v in pairs(extension_list) do
      ext_list_m:add_item{text=k,sub_menu=function() return persistence_menu(v,current_pos) end}
    end
  end
  return ext_list_m
end

local ext_m = nil
function module.extensions_menu(c)
  current_client = c
  if not ext_m then
    ext_m = radical.context{}
    ext_m:add_item{text="Overlay widget", sub_menu=function() return extension_list_menu( "overlay" ) end }
    ext_m:add_item{text="Prefix widget" , sub_menu=function() return extension_list_menu( "prefix"  ) end }
    ext_m:add_item{text="Suffix widget" , sub_menu=function() return extension_list_menu( "suffix"  ) end }
  end
  return ext_m
end

function module.add(name,f)
  extension_list[name] = f
  if ext_list_m then
    ext_list_m:add_item{text=name,sub_menu=function() return persistence_menu(f) end}
  end
end

return module
-- kate: space-indent on; indent-width 2; replace-tabs on;
