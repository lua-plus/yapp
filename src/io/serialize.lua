
--- Serialize a value into a lua-ready table.
---@param value any
---@param depth number
---@return string
local function serialize_internal(value, depth)
    local t = type(value)

    if t == "nil" then
        return "nil"
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        return ("%q"):format(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "table" then
        -- check for empty tables.
        if next(value) == nil then
            return "{}"
        end

        local entries = {}

        for _, v in ipairs(value) do
            table.insert(entries, serialize_internal(v, depth + 1))
        end

        for k, v in pairs(value) do
            if type(k) ~= "number" then
                local v_str = serialize_internal(v, depth + 1)

                -- if the key is a valid lua variable name it doesn't need brackets.
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    table.insert(entries, string.format(
                        "%s = %s",
                        k, v_str
                    ))
                else
                    table.insert(entries, string.format(
                        "[%s] = %s",
                        serialize_internal(k, 0), v_str
                    ))
                end
            end
        end

        local join = "\n" .. ("\t"):rep(depth + 1)

        return "{" .. join .. table.concat(entries, "," .. join) .. "\n" .. ("\t"):rep(depth) .. "}"
    elseif t == "function" then
        return ("-- This function has been dumped to serialize nicely\nload(%q)()"):format(string.dump(value))
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
---@return string
local function serialize (value)
    return serialize_internal(value, 0)
end

return serialize