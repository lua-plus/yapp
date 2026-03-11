
-- TODO Properties mixin that like stringifies properties nicely? idk. just
-- would be useful.

local get_properties = require("src.__internal.class.get_properties")

local Properties = {
    print_properties = function (self)
        print(self:stringify_properties())
    end,

    stringify_properties = function (self)
        return table.concat(self:get_properties(), ", ")
    end,

    get_properties = function (self)
        return get_properties.names(self)
    end
}

return Properties