local globals = require("src.__internal.globals")
globals.init(_G)

local namespace = require("src.__internal.namespace")

local name, path = ...

return namespace(name, path, {
    _VERSION = "0.1.0"
})