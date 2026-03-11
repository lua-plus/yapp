local debug_repo = require("wip.debug.HotLoader.debug_repo")

local shim = {}

---@protected
---@type metatable
shim._func_mt = {
    __call = function(t, ...)
        return t[1](...)
    end,
    __tostring = function(t)
        return tostring(t[1])
    end
}

--- If a shim can be created, do so and return it.
---@param mod any
---@return any new_mod
function shim.create(mod)
    if type(mod) == "function" then
        -- TODO warning for setupvalue

        -- create a new function shim...
        if debug_repo.setupvalue then
            local inner = mod

            -- ...that is a closure
            return function(...)
                return inner(...)
            end
        else
            -- ...that is a callable table
            return setmetatable({ mod }, shim._func_mt)
        end
    end

    return mod
end

--- Attempt to in-place update a given value, if possible. Returns boolean for
--- if it succeeded
---@param existing any
---@param new any
---@return boolean ok
function shim.reshim (existing, new)
    local t_existing = type(existing)
    local t_new = type(new)

    if t_existing == "function" and debug_repo.setupvalue then
        if t_new ~= "function" then
            return false
        end

        debug_repo.setupvalue(existing, 1, new)

        return true
    end

    if t_existing ~= "table" then
        return false
    end

    if t_new == "function" then
        -- we want a function shim, but we have some other table
        if getmetatable(existing) ~= shim._func_mt then
            -- vacuum entries
            for k in pairs(existing) do
                existing[k] = nil
            end

            setmetatable(existing, shim._func_mt)
        end

        existing[1] = new

        return true
    end

    if t_new == "table" then
        local mt = getmetatable(new)
        setmetatable(new, nil)

        setmetatable(existing, nil)

        -- vacuum entries
        for k in pairs(existing) do
            existing[k] = new[k]
            new[k] = nil
        end
        -- and insert new ones
        for k, v in pairs(new) do
            existing[k] = v
        end

        setmetatable(existing, mt)

        return true
    end

    return false
end

return shim