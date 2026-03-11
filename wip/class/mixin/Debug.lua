local named_mixin = require("src.__internal.class.mixin.named_mixin")
local get_properties = require("src.__internal.class.get_properties")

--- A debug mixin that gives known properties, mixins, etc.
local Debug = named_mixin("Debug", {
    debug = function (self)
        local kind = self.class and "instance of" or "class"
        
        local class = self.class or self
        local class_name = tostring(class):match("^class '([^']*)'")

        local addr = tostring(self):match("%(table: (0x%x+)%)$")

        local properties = table.concat(get_properties.names(self), ", ")

        return ("%s %s\n\taddress: %s\n\tknown properties: %s"):format(kind, class_name, addr, properties)
    end
})

return Debug