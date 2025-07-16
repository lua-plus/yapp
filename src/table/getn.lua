
local type = type
local max = math.max

---@param t table
---@return integer
local table_getn = function (t)
    local n = t.n
    if type(n) ~= "number" then
        n = 0
    end

    return max(#t, n)
end

return table_getn