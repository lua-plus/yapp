
---@return any current
---@return function enqueue
local function iter_queue_iter(input)
    local queue, enqueue = input[1], input[2]

    local value = table.remove(queue, 1)

    return value, enqueue
end

---@generic T
---@param seed T
---@return fun(state: [T[], function]): (T, fun(value: T))
---@return [T[], function] state
local function iter_queue(seed)
    local queue = { seed }

    local enqueue = function(value)
        table.insert(queue, value)
    end

    local state = { queue, enqueue }

    return iter_queue_iter, state
end

return iter_queue