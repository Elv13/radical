-- This is a shim module to use the new `awful.tooltip` instead of Radical
-- old implementation. Most features have been merged upstream and it is
-- no longer necessary to keep a Radical version of this.
--
-- Also, this forces me to finish awful.tooltip instead of using my own.

local tooltip = require("awful.tooltip")

return function(parent, text, args)
    return tooltip{markup="<b>"..text.."</b>", objects = {parent}, mode = "outside"}
end

-- kate: space-indent on; indent-width 4; replace-tabs on;
