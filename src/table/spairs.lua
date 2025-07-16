local unpack = require("src.table.unpack")

---@alias Yapp.Table.Spairs.State [string[], table<string, integer>, table]

--- An overcomplicated next re-implementation
---@param t_in Yapp.Table.Spairs.State
---@param last_key any
---@return any, any
local function spairs_iter(t_in, last_key)
    local keys, indices, t = unpack(t_in)

    local index = last_key ~= nil and
        (indices[last_key] + 1) or 1

    local key = keys[index]

    return key, t[key]
end

--- "sorted pairs" - like calling `pairs` but keys (even non-string ones!) will
--- always be traversed in alphabetical order.
---
--- Note that time complexity is not good.
---@generic K : any, V : any
---@param t table<K, V>
---@return fun(t_in: Yapp.Table.Spairs.State, last_key: any): K, V
---@return Yapp.Table.Spairs.State
---@return nil
local function sorted_pairs(t)
    local keys = {}
    for key in pairs(t) do
        table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local indices = {}
    for i, key in pairs(keys) do
        indices[key] = i
    end

    local t_out = { keys, indices, t }

    return spairs_iter, t_out, nil
end

return sorted_pairs
