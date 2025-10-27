
---@generic K
---@param t table<K, any>
---@return K[]
local function table_keys(t)
    -- TODO FIXME allow iteration via mt
    local keys = {}

    for k in pairs(t) do
        table.insert(keys, k)
    end

    return keys
end

return table_keys