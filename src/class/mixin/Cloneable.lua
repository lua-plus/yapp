local get_properties = require("src.__internal.class.get_properties")
local named_mixin = require("src.__internal.class.mixin.named_mixin")
local Verify = require("src.class.mixin.Verify")
local expect_properties = require("src.__internal.class.mixin.expect_properties")

local Cloneable = named_mixin("Cloneable", {
    clone = function(self)
        local class = self.class
        local instance = class()

        for _, name in ipairs(get_properties.names(self)) do
            local value = get_properties.get(self, name)
            get_properties.set(instance, name, value)
        end

        return instance
    end,

    [Verify.verification] = function(class, properties)
        local expected, unexpected = expect_properties(class, properties)

        if #expected == 0 and #unexpected == 0 then
            return true
        end

        local err_expected =
            #expected == 1 and ("Expected cloneable property %s"):format(expected[1]) or
            #expected >= 2 and ("Expected cloneable properties %s"):format(table.concat(expected, ", ")) or
            nil

        local err_unexpected =
            #unexpected == 1 and ("Unexpected cloneable property %s"):format(unexpected[1]) or
            #unexpected >= 2 and ("Unexpected cloneable properties %s"):format(table.concat(unexpected, ", ")) or
            nil

        return false, table.concat({ err_expected, err_unexpected }, ". ")
    end
})

return Cloneable
