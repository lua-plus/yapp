
---@return any current
---@return function enqueue
local function iter_stack_iter(input)
    local stack, push = input[1], input[2]

    local value = table.remove(stack)

    return value, push
end

---@generic T
---@param seed T
---@return fun(state: [T[], function]): (T, fun(value: T))
---@return [T[], function] state
local function iter_stack(seed)
    local stack = { seed }

    local push = function(value)
        table.insert(stack, value)
    end

    local state = { stack, push }

    return iter_stack_iter, state
end

return iter_stack