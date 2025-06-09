local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist.")

--- Get the name of a function or method
---@param fn function
---@return string
local function get_name(fn)
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

    local r

    -- function <name>
    r = defline:match("function%s+([%a_][%w%._:]*)%s*%(")
    if r then
        return r
    end

    -- <name> = function
    r = defline:match("%s([%a_][%w%._]*)%s*=%s*function")
    if r then
        return r
    end

    return "unknown (no match)"
end

return get_name
