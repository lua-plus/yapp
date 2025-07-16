---@generic K, T
---@param t table<K, T>
---@param predicate fun(item: T, key: K, table: table<K, T>): boolean
---@return table<K, T>
local function filter(t, predicate)
    local ret = {}

    for k, v in pairs(t) do
        if predicate(v, k, t) then
            if type(k) == "number" then
                table.insert(ret, v)
            else
                ret[k] = v
            end
        end
    end

    return ret
end

return filter
