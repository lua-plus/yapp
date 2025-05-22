
local globals = require("src.__internal.globals")
globals.init(_G)

local global_names = globals.get_names()

--- Serialize a value into a lua-ready table.
---@param value any
---@param soft boolean?
---@param depth number
---@param traversed table
---@return string
local function serialize_internal(value, soft, depth, traversed)
    local t = type(value)

    if t == "table" or t == "function" then
        local global_name = global_names[value]
        if global_name then
            return global_name
        end            
    end

    if t == "nil" then
        return "nil"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        return ("%q"):format(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "table" then
        if traversed[value] then
            if soft then
                return "(recursive table)"
            end
    
            error("Cannot serialize recursive values")
        end
        traversed[value] = true

        -- check for empty tables.
        if next(value) == nil then
            return "{}"
        end

        local entries = {}

        for _, v in ipairs(value) do
            table.insert(entries, serialize_internal(v, soft, depth + 1, traversed))
        end

        for k, v in pairs(value) do
            if type(k) ~= "number" then
                local v_str = serialize_internal(v, soft, depth + 1, traversed)

                -- if the key is a valid lua variable name it doesn't need brackets.
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    table.insert(entries, string.format(
                        "%s = %s",
                        k, v_str
                    ))
                else
                    table.insert(entries, string.format(
                        "[%s] = %s",
                        serialize_internal(k, soft, 0, traversed), v_str
                    ))
                end
            end
        end

        local join = "\n" .. ("\t"):rep(depth + 1)

        return "{" .. join .. table.concat(entries, "," .. join) .. "\n" .. ("\t"):rep(depth) .. "}"
    elseif t == "function" then
        if soft then
            return "(function)"
        end

        return ("--[[ (Serialized function) ]] load(%q)()"):format(string.dump(value))
    elseif t == "thread" then
        error("Cannot serialize thread")
    elseif t == "userdata" then
        error("Cannot serialize userdata")
    else
        return "nil"
    end
end

--- Serialize a value into a lua-ready table.
---@param value any
---@param soft boolean?
---@return string
local function serialize (value, soft)
    return serialize_internal(value, soft, 0, {})
end

return serialize