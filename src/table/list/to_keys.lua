
--- Convert a list to a name-value table for efficient lookups.
---
---@generic T, V : true
---@param list T[]
---@param values V[] | nil
---@return table<T, V>
local function list_to_keys (list, values)
    values = values or {}
    
    local keys = {}
    for k, v in pairs(list) do
        keys[v] = values[k] or true
    end

    return keys
end

return list_to_keys