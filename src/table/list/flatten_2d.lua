
--- Consume a list of lists and return a list of all their contents.
---@generic T
---@param list T[][]
---@return T[]
local function flatten(list)
    local ret = {}
    for _, sub in ipairs(list) do
        for _, entry in ipairs(sub) do
            table.insert(ret, entry)
        end
    end

    return ret
end

return flatten