local class = require("lib.30log")
local get_properties = require("src.__internal.class.get_properties")
local Equivalent = require("src.class.mixin.Equivalent")

local Class = class("Class", {
    [Equivalent] = {
        string = false
    }
}):with(Equivalent)

function Class:get_string()
    return self._string
end

function Class:set_string(string)
    self._string = string
end

function Class:init() end

local a = Class()
a:set_string("get_string")

local b = Class()

print(a == b)
-- print(get_properties.names(Class))
