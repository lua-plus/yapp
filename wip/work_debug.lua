
local class = require("lib.30log")
local Debug = require("wip.class.mixin.Debug")

local Class = class("Class"):with(Debug)

print(Class:debug())
print(Debug.debug(Class()))