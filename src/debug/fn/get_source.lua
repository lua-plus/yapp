
local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist.")

---@param fn function
local function get_source (fn)
    local info = debug_getinfo(fn, "S")

    if info.short_src == "[C]" then
        return "(C function)"
    end

    return string.format("%s:%d", info.short_src, info.linedefined)
end

return get_source