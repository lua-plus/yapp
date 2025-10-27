
local debug_getupvalue = assert((debug or {}).getupvalue, "debug.getupvalue must exist")

local getfenv = require("src.debug.env.getfenv")

---@doc
--- A stateless iterator that provides the upvalues of a given function.
--- Even under Lua 5.1, the iterator's results will include _ENV.
--- 
--- **Usage**
--- ```lua
---     local message = "Hello World!"
---     local function my_function ()
---         print(message)
---     end
---     
---     for name, value, index in upvalues(my_function) do
---         print(name, value, index)
---     end
--- ```
--- The above example will print the name, value, and upvalue index of _ENV and message

local needs_getenv = _VERSION == "Lua 5.1"

---@param state [function, integer]
---@return string? name, any? value, integer? index
local function upvalues_iter(state)
    local fn, index = state[1], state[2]

    if needs_getenv then
        if index == 1 then
            state[2] = state[2] + 1
            
            return "_ENV", getfenv(fn), 1
        end

        index = index - 1
    end

    local name, value = debug_getupvalue(fn, index)

    if name then
        state[2] = state[2] + 1

        return name, value, index
    else
        return nil, nil
    end
end

---@param fn function
local function upvalues(fn)
    return upvalues_iter, { fn, 1 }
end

return upvalues