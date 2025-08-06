local iter_queue = require("src.iter_queue")

--- Create a table whose values are defined by each table in ..., in order,
--- deeply.
---@generic T
---@param ... T
---@return T
local function crush_deep (...)
    local argv = select("#", ...)
    local args = { ... }

    -- Table held backwards
    local tables = {}
    for i=argv,1, -1 do
        local arg = args[i] 
        if arg then
            table.insert(tables, arg)
        end
    end

    local out = {}

    for state, enquue in iter_queue({ tables, out }) do
        local tables = state[1]
        local out = state[2]

        local keys = {}
        for _, table in ipairs(tables) do
            for k in pairs(table) do
                keys[k] = true
            end
        end

        for k in pairs(keys) do
            for i, t in ipairs(tables) do
                local v = t[k]
                
                if type(v) == "table" then
                    -- Construct a list of tables that have this key w/ a table
                    -- we know that it must be from i + 1 onwards.
                    local sub_tables = { v }
                    for j=i + 1,#tables do
                        local other_table = tables[j]
                        local sub_v = other_table[k]

                        if type(sub_v) == "table" then
                            table.insert(sub_tables, sub_v)
                        end
                    end

                    local sub_out = {}
                    enquue({ sub_tables, sub_out })

                    out[k] = sub_out
                    break
                elseif v ~= nil then
                    out[k] = v
                    break
                end
            end
        end
    end

    return out
end

return crush_deep