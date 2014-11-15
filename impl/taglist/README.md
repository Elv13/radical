Radical Taglist
===============

This is the radical re-implementation of awful.taglist. It is mostly simmilar,
but not identical to the former implementation. Some concepts, such as "focussed"
tags have been simplified in being a list of selected tags (ignoring the focus).

### Why?

The old taglist is inflexible and doesn't allow newer concepts to be introduced.
The "Blind" module tried to make it look nice, but rely on dirty hacks and has
limitations while the "Tyrannical" module tried to implement Xmodad style
screen independant tags. Some other users also tried to implement multi-screen
tags, but also failed. This is because there is a missing abstraction layer
between the taglist and the tags. This module aim to fix this.

Plus, it inherit Radical style and layouts engines for both item and style, so
this module could technically be used as a box menu or something like that
without modifications.

### Options

taglist_watch_name_changes | Make the tag state `changed` if a client title change

### Beautiful options

taglist_bg_selected
taglist_fg_selected

taglist_bg
taglist_fg
taglist_bg_hover
taglist_fg_hover
taglist_bg_used
taglist_fg_used
taglist_bg_urgent
taglist_fg_urgent
taglist_bg_cloned
taglist_fg_cloned
taglist_bg_changed
taglist_fg_changed
taglist_default_icon
taglist_style
taglist_default_item_margins
taglist_default_margins
taglist_disable_index
taglist_fg_prefix
taglist_disable_icon
taglist_icon_transformation

States:
empty
cloned
highlight