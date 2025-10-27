
local debug_getlocal = assert((debug or {}).getlocal, "debug.getlocal must exist")

---@param state [function|integer, integer]
---@return string? name, any? value, integer? index
local function locals_iter(state)
    local fn, index = state[1], state[2]

    local name, value = debug_getlocal(fn, index)

    if name then
        state[2] = state[2] + 1

        return name, value, index
    else
        return nil, nil
    end
end

---@overload fun(index: integer)
---@param fn function
local function locals(fn)
    if type(fn) == "number" then
        ---@diagnostic disable-next-line:cast-local-type
        fn = fn + 1
    end

    return locals_iter, { fn, 1 }
end

return locals