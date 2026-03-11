local serialize = require("src.io.serialize")
local fancy_options = require("src.__internal.io.serialize.fancy_options")

-- TODO FIXME fails to print debug.getregistry()

--- Print an output more similar to Node.js
---@param ... any
local function print(...)
    local argv = select("#", ...)
    local args = { ... }

    local stdout = io.stdout

    for i = 1, argv do
        local arg = args[i]

        local str = ""
        if type(arg) == "string" then
            str = arg
        else
            str = serialize(arg, fancy_options)
        end
        stdout:write(str)

        if i ~= argv then
            stdout:write(" ")
        end
    end
    stdout:write("\n")
end

return print
