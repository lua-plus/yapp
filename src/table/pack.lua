
local table_pack = table.pack or function (...)
    ---@type table
    local t = {...}
    t.n = select("#", ...)

    return t
end

return table_pack