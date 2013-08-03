# Radical - A menu system for Awesome WM
========================================

This is Radical, one of the largest Awesome extension module. It provide un
unified interface to generate multiple types of menus.

## Installation

Installing Radical is simple, just move to ~/.config/awesome and clone the
repository

```sh
cd ~/.config/awesome
git clone https://github.com/Elv13/radical.git
```

The require it at the top of your rc.lua:

```lua
    local radical = require("radical")
```

## Usage

Unlike awful.menu, radical act like other Awesome 3.5 layouts. You need to add
items one by one. This have the benefit of letting you interact with the items
themselves programatically.

The most simple kind of menus, contexts one, can be created like this:

```lua
    local menu = radical.context({})
    menu:add_item({text="Screen 1",button1=function() print("Hello World! ") end})
    menu:add_item({text="Screen 9",icon=beautiful.path.."Icon/layouts/tileleft.png"})
    menu:add_item({text="Sub Menu",sub_menu = function()
        local smenu = radical.context({})
        smenu:add_item({text="item 1"})
        smenu:add_item({text="item 2"})
        return smenu
    end})
```

In this example, a simple 3 item menu is created with a dynamically generated
submenu. Please note that generating submenus using function will generate it
every time it is being shown. For static menus, it is faster to simply create
them once and passing the submenu object to the "sub_menu" item property.

### Menu types

The current valid types are:

 * **Context:** Regular context menu
 * **Box:** Centered menus (think Windows alt-tab menu)
 * **Embed:** Menus in menus. This can be used as subsections in large menus

### Menu style

Each menus come in various styles for various applications. New style can also
be created by beautiful themes. The current ones are:

 * **Arrow:** Gnome3 and Mac OSX like menus with border radius and an arrow
 * **Classic:** Replicate awful.menu look

### Item style

Like menus, items can have their own style. Valid values:

 * **Basic:** The most simple kind of items, no borders or special shape
 * **Classic:** 1px border at the end of each items
 * **Rounded:** A 3px border radius at each corner

### Menu layouts

On top of each styles, menu can also have different layouts to display items:

* **Vertical:** Items are displayed on top of each other
* **Horizontal:** Items are displayed alongside each other
* **Grid:** Items are displayed as a 2D array

### Using styles and layouts

```lua
    local radical = require("radical")
    
    local m = radical.context({
        style      = radical.style.classic      ,
        item_style = radical.item_style.classic ,
        layout     = radical.layout.vertical    })
    
```