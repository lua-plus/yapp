local crush = require("src.table.crush")
local get_source = require("src.debug.fn.get_source")

-- TODO FIXME finish this.

local debug_getinfo = assert((debug or {}).getinfo,
    "debug.getinfo must exist")

--- Like debug.fn.get_name, but matches Function 
---@param fn function
local function Function_get_name(fn)
    ---@diagnostic disable-next-line:undefined-field
    local info = debug_getinfo(fn, "S")

    if info.what == "C" then
        return "(C)"
    end

    local source = info.source
    source = source:sub(2)

    local f, err = io.open(source, "r")
    if not f then
        return string.format("unknown (Error opening file: %s)", err)
    end

    local line = info.linedefined

    local defline
    for _ = 1, line do
        defline = f:read("l")
    end

    return defline:match("local%s+([a-zA-Z_][a-zA-Z0-9_]*)%s*=%s*Function%(")
        or "unknown (unable to match)"
end

local Function_getters = {
    name = Function_get_name,
    source = get_source
}

---@class Yapp.Function
---@field name string
---@field source string
---@field protected func function
---
---@operator call:(Yapp.Function|function)
local Function = {}
local F_mt
local F_inst_mt
F_mt = {
    __index = function(t, k)
        local getter = Function_getters[k]
        if getter then
            local val = getter(t.func)
            t[k] = val
            return val
        end
    end,
    __call = function(_, f)
        local instance = { func = f }

        setmetatable(instance, F_inst_mt)

        return instance
    end,
    __name = "Function",
    __pairs = function (t)
        for name in pairs(Function_getters) do
            local _ = t[name]
        end

        return next, t, nil
    end
}
F_inst_mt = crush(F_mt, {
    __call = function(t, ...)
        return t.func(...)
    end
})
setmetatable(Function, F_mt)

return Function
