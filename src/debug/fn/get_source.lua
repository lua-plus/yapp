
local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist.")

--- Get the filename and line number of a given function
---@param fn function
local function get_source (fn)
    local info = debug_getinfo(fn, "S")

    if info.what == "C" then
        return "(C function)"
    end

    local src = info.source:sub(2)

    return string.format("%s:%d", src, info.linedefined)
end

return get_source