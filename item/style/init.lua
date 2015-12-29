local holo = require("radical.item.style.holo")
local rounded = require("radical.item.style.rounded"       )

return {
    basic          = require("radical.item.style.basic"        ),
    classic        = require("radical.item.style.classic"      ),
    subtle         = require("radical.item.style.subtle"       ),
    rounded_shadow = rounded.shadow                             ,
    rounded        = rounded                                    ,
    holo           = holo                                       ,
    holo_top       = holo.top                                   ,
    arrow_alt      = require("radical.item.style.arrow_alt"    ),
    arrow_prefix   = require("radical.item.style.arrow_prefix" ),
    arrow_single   = require("radical.item.style.arrow_single" ),
    arrow_3d       = require("radical.item.style.arrow_3d"     ),
    slice_prefix   = require("radical.item.style.slice_prefix" ),
    line_3d        = require("radical.item.style.line_3d"      ),
}
