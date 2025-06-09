local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist.")

--- Try to get the text wherein a lua function was defined
---@param fn function
---@return string
local function get_chunk(fn)
    local info = debug_getinfo(fn, "S")

    if info.what == "C" then
        return "(C function - cannot introspect)"
    end

    local source = info.source
    source = source:sub(2)

    local f, err = io.open(source, "r")
    if not f then
        return string.format("(Error opening file: %s)", err)
    end

    local buffer = {}

    local i_line = 0
    for s_line in f:lines() do
        i_line = i_line + 1

        if i_line == info.lastlinedefined + 1 then
            -- Return buffer as is
            break
        elseif s_line:match("^%s*%-%-") or i_line >= info.linedefined then
            -- Preserve comments
            table.insert(buffer, s_line)
        else
            -- Reset buffer otherwise
            buffer = {}
        end
    end

    return "\n\n" .. table.concat(buffer, "\n") .. "\n\n"
end

return get_chunk
