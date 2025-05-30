---@generic K, T, R
-- ---@overload fun(t: T[], cb: fun(item: T, index: number, list: T[]): R): R[]
---@param t table<K, T>
---@param cb fun(item: T, key: K, table: table<K, T>): R
---@return table<K, R>
local function table_map (t, cb)
    local ret = {}

    for k, v in pairs(t) do
        ret[k] = cb(v, k, t)
    end

    return ret
end

return table_map