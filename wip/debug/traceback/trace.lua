local debug_getinfo = assert((debug or {}).getinfo, "debug.getinfo must exist")

local globals = require("src.__internal.globals")
local fancy_options = require("src.__internal.io.serialize.fancy_options")
local crush_deep = require("src.table.crush_deep")
local serialize = require("src.io.serialize")
local chalk = require("src.term.chalk")

--[[

Improvements over debug.traceback
 - colorized by default
 - stops at pcall/xpcall boundaries
 - consumes non-string messages properly.

]]

---@alias Yapp.Debug.Trace.Options {
---     format: {
---         message: (fun(message: any): string),
---         line: (fun(info: debuginfo): string),
---     },
---     terminals: { [function]: true },
---}

local trace = {}

-- TODO FIXME as much as this module is nice and tidy and neat, it should
-- replicate the behavior of debug.traceback as much as possible. We need a
-- separate feature to parse & betterify errors on a root-level xpcall

--- TODO publish this as fancy options, make truly default options accessible.
---@type Yapp.Debug.Trace.Options
local default_options = {
    format = {
        message = function(message)
            return serialize(message, fancy_options)
        end,
        line = function(info)
            local source
            do
                if info.what == "C" then
                    source = "[C]"
                else 
                    source = string.format("%s:%d", info.short_src, info.currentline)
                end
            end
            
            local name
            do
                if info.what == "main" then
                    name = chalk.blue("main chunk")
                elseif info.name then
                    if info.namewhat == "global" then
                        name = chalk.blue(string.format("global '%s'", info.name))
                    elseif info.namewhat == "local" then
                        name = chalk.blue(string.format("local '%s'", info.name))
                    elseif info.namewhat == "upvalue" then
                        name = chalk.blue(string.format("upvalue '%s'", info.name))
                    else
                        print(info)
                    end
                else 
                    name = serialize(info.func, fancy_options)
                end
            end

            return string.format("%s: in %s", chalk.magentaBright(source), name)
        end,
    },
    terminals = {
        [_G.xpcall] = true,
        [_G.pcall] = true,

        -- TODO under luau, terminate for ypcall
    }
}

---@return thread thread
---@return string | nil message
---@return integer level
---@return Yapp.Debug.Trace.Options options
function trace._consume_args(...)
    local argv = { ... }

    local thread = type(argv[1]) == "thread" and
        table.remove(argv, 1) or
        coroutine.running()

    local message = argv[1]
    local level = argv[2] or 1

    ---@type Yapp.Debug.Trace.Options
    local options = crush_deep(argv[3] or {}, default_options)
    if message ~= nil and type(message) ~= "string" then
        message = options.format.message(message)
    end

    return thread, message, level, options
end

---@overload fun(thread: thread, message?: any, level?: integer, options?: Yapp.Debug.Trace.Options)
---@overload fun(message?: any, level?: integer, options?: Yapp.Debug.Trace.Options)
---@param ... nil
function trace.traceback(...)
    local thread, message, level, options = trace._consume_args(...)

    local lines = {}
    local terminals = options.terminals
    local format_line = options.format.line
    while true do
        level = level + 1

        local info = debug_getinfo(thread, level, "Sfln")
        if not info then
            break
        end

        table.insert(lines, format_line(info))

        if terminals[info.func] then
            break
        end
    end

    local lines_s = table.concat(lines, "\n\t")

    -- TODO cheap 'traceback stacking' solution - when we get a message, we
    -- check for "stack traceback:" and if it's included there we don't include
    -- another.

    return (message and (message .. "\n") or "") .. "stack traceback:\n\t" .. lines_s
end

--- Call the given callback function, and re-interpret the value
---@param cb function
function trace.catch_errors(cb)
    local ok, err = xpcall(cb, function (err)
        local location, message = err:match("(.-):%s(.*)")

        local new_err = chalk.red("Error: ") .. chalk.magentaBright(location) .. ": " .. message

        return trace.traceback(new_err)
    end)

    if not ok then
        print(err)

        os.exit(false)
    end
end

return trace
