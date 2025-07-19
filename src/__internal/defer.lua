
-- I may never trust this API

---@diagnostic disable-next-line:deprecated
local newproxy = newproxy
local getmetatable = getmetatable
local setmetatable = setmetatable
local pack = require("src.table.pack")
local unpack = require("src.table.unpack")

--- Defer a task until the garbage collector feels like executing it.
---@param cb function
---@param ... any
local function defer(cb, ...)
    local args = pack(...)
    local gc = function()
        cb(unpack(args))
    end

    if newproxy then
        local p = newproxy(true)
        local mt = getmetatable(p)

        mt.__gc = gc
    else
        setmetatable({}, {
            __gc = gc
        })
    end
end

return defer
