
local get_properties = require("src.__internal.class.get_properties")

local Cloneable = {
    clone = function (self)
        local class = self.class
        local instance = class()

        for _, name in ipairs(get_properties.names(self)) do
            local value  = get_properties.get(self, name)
            get_properties.set(instance, name, value)
        end

        return instance
    end
}

return Cloneable