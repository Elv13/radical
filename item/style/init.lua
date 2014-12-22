local holo = require("radical.item.style.holo")

return {
    basic        = require("radical.item.style.basic"        ),
    classic      = require("radical.item.style.classic"      ),
    subtle       = require("radical.item.style.subtle"       ),
    rounded      = require("radical.item.style.rounded"      ),
    holo         = holo                                       ,
    holo_top     = holo.top                                   ,
    arrow_alt    = require("radical.item.style.arrow_alt"    ),
    arrow_prefix = require("radical.item.style.arrow_prefix" ),
    arrow_single = require("radical.item.style.arrow_single" ),
    arrow_3d     = require("radical.item.style.arrow_3d"     ),
    slice_prefix = require("radical.item.style.slice_prefix" ),
}