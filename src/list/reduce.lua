
local nil_coalesce = require("src.nil_coalesce")

---@generic T, Initial, R
---@param list T[]
---@param cb fun(previous: Initial, current_value: T, current_index: number, list: T[]): R
---@param initial Initial
---@return R
local function list_reduce (list, cb, initial)
    local reduction = nil_coalesce(initial, list[1])

    for i, value in ipairs(list) do
        reduction = cb(reduction, value, i, list)
    end

    return reduction
end

return list_reduce