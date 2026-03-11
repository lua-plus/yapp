local Verify = require("src.class.mixin.Verify")
local Cloneable = require("src.class.mixin.Cloneable")
local Properties = require("wip.class.mixin.Properties")

local class = require("lib.30log")

local Class = class("Class", {
    [Verify] = {
        [Cloneable] = { "value" }
    }
}):with(Cloneable):with(Verify):with(Properties)

function Class:set_value()

end

function Class:get_value ()

end

function Class:init() end

return Class
