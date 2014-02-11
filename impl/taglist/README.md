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