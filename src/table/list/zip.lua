
-- TODO write some overloads

--- Given multiple iterables, return a single table of those values
---@param ... table | userdata
---@return table
local function zip (...)
    local ins = { ... }

    local max_len = 0
    for _, t in ipairs(ins) do
        if #t > max_len then
            max_len = #t
        end
    end

    local outs = {}
    for i=1,max_len do
        local out = {}
        
        for j, t in ipairs(ins) do
            out[j] = t[i]
        end

        outs[i] = out
    end

    return outs
end

return zip