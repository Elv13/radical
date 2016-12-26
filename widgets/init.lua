-- Do some evil monkeypatching for upstreamable widgets
local wibox = require("wibox")

wibox.layout.grid     = require( "radical.widgets.grid"     )
-- wibox.widget.checkbox = require( "radical.widgets.checkbox" )
-- wibox.widget.slider   = require( "radical.widgets.slider"   )

return {
    scroll          = require( "radical.widgets.scroll"          ),
    filter          = require( "radical.widgets.filter"          ),
    fkey            = require( "radical.widgets.fkey"            ),
    table           = require( "radical.widgets.table"           ),
    header          = require( "radical.widgets.header"          ),
    piechart        = require( "radical.widgets.piechart"        ),
    separator       = require( "radical.widgets.separator"       ),
    infoshapes      = require( "radical.widgets.infoshapes"      ),
    constrainedtext = require( "radical.widgets.constrainedtext" ),
}
