local get_properties = require("wip.class.util.get_properties")
local Cloneable = require("wip.class.mixin.Cloneable")

local VirtualFileHandle = require("src.class.VirtualFileHandle")

VirtualFileHandle:with(Cloneable)

local h = VirtualFileHandle()

h:set_mode("r+")

print(h)
print(h:get_mode())

local clone = h:clone()
print(clone)
print(clone:get_mode())
