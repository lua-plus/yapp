local is_lua_name = require("src.io.serialize.util.is_lua_name")

---@param t table
---@param ser fun(item: any): string
---@return string[]
local function get_table_entries(t, ser)
    local entries = {}

    -- track the highest index because ipairs stops at first nil
    local i_max = 0
    for i, v in ipairs(t) do
        table.insert(entries, ser(v))

        i_max = i
    end

    for k, v in pairs(t) do
        local t_k = type(k)

        -- is_number -> k > i_max
        -- not is_number or k > i_max
        -- TODO k < 1 keys should be placed previous to ipairs results.
        if t_k ~= "number" or k > i_max or k < 1 then
            -- if the key is a valid lua variable name it doesn't need brackets
            local k_str = is_lua_name(k) and k or "[" .. ser(k) .. "]"

            local v_str = ser(v)

            table.insert(entries, k_str .. " = " .. v_str)
        end
    end

    return entries
end

return get_table_entries