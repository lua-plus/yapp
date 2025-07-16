
local globals = require("src.__internal.globals")
globals.init(_G)
local _, get_source = pcall(require, "src.debug.fn.get_source")

local global_names = globals.get_names()

-- TODO rewrite this guy:
-- allow option for max depth
-- allow option for color
-- allow option for iterator (eg spairs)
-- allow options for handling 'bad' tables?
 
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
        local mt = getmetatable(value) or {}

        if traversed[value] or mt.__index == value then
            if soft then
                return "(recursive table)"
            end
    
            error("Cannot serialize recursive values")
        end
        traversed[value] = true

        if soft and mt.__tostring then
            return string.format("%q", tostring(value))
        end

        local entries = {}

        for _, v in ipairs(value) do
            table.insert(entries, serialize_internal(v, soft, depth + 1, traversed))
        end

        for k, v in pairs(value) do            
            -- check for recursively self-generating objects like chalk
            if mt.__pairs and mt == getmetatable(v) and getmetatable(v[k] or {}) == mt then
                if soft then
                    return "(deep self-generating table)"
                end

                error("Cannot serialize deep self-generating tables")
            end

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

        if #entries == 0 then
            return "{}"
        end

        local join = "\n" .. ("\t"):rep(depth + 1)

        return "{" .. join .. table.concat(entries, "," .. join) .. "\n" .. ("\t"):rep(depth) .. "}"
    elseif t == "function" then
        if soft then
            if get_source then
                return string.format("[function %s]", get_source(value))
            end
            return "[function]"
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