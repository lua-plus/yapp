local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist")

local globals = require("src.__internal.globals")

local trace = {}

local trace_term = {
    [_G.xpcall] = true,
    [_G.pcall] = true
}
trace.terminals = trace_term

--[[
TODO rework this guy:
 - allow creating rulesets, which returns a minimal closure to trace with that ruleset.
    - eg, in promises:
        - ignore self (make an easy API for 'ignore self' using caller info)
        - terminate at pcall/xpcall boundary
 - __call behavior matches vanilla exactly except 
     - use src.__internal.thread_names when possible (if traceback called w/ thread arg)
 - think about performance
]]

---@param info table
local function trace_get_source(info)
    if info.what == "C" then
        return "[C]"
    else
        return string.format("%s:%d", info.short_src, info.currentline)
    end
end

---@param info table
local function trace_get_name(info)
    local global = globals.get_names()[info.func]
    if global then
        return string.format("function '%s'", global)
    elseif info.what == "main" then
        return "main chunk"
    elseif info.what == "C" then
        return "?"
    elseif info.name then
        return string.format("local '%s'", info.name)
    end

    return string.format("function <%s:%d>", info.short_src, info.linedefined)
end

-- TODO original has overload for (thread, message, level) but seems to do nothing
-- TODO original acts the same as tostring (like, no traceback) when passed a message that is neither string nor number.
-- TODO maybe message=table should be automatically concat'ed

--- Similar to debug.traceback, but tracing stops at pcall/xpcall boundaries, to
--- create more easily 'stackable' tracebacks, such as concatenating tracebacks through multiple
---@param message any
function trace.traceback(message)
    message = tostring(message)

    local trace_list = { message .. "\nstack traceback:" }

    local idx = 1

    while true do
        idx = idx + 1

        local info = debug_getinfo(idx, "Sfl")
        if not info then
            break
        end

        local src = trace_get_source(info)

        local name = trace_get_name(info)

        table.insert(trace_list, string.format(
            "%s: in %s", src, name
        ))

        if trace_term[info.func] then
            break
        end
    end

    return table.concat(trace_list, "\n\t")
end

setmetatable(trace, {
    __call = function(t, ...)
        return t.traceback(...)
    end
})

return trace
