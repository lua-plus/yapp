local get_properties = require("src.__internal.class.get_properties")

--- A general helper for verification. Returns expected properties that are
--- missing, and unexpected properties that were found
---@param class Log.Class
---@param properties string[] | table<string, true>
---@return string[] expected, string[] unexpected
local function expect_properties(class, properties)
    local names = get_properties.names(class)

    local unexpected = {}

    local k_expected = {}
    for k, v in pairs(properties) do
        if type(k) == "number" then
            k_expected[v] = true
        else
            k_expected[k] = true
        end
    end

    for _, name in ipairs(names) do
        if not k_expected[name] then
            table.insert(unexpected, "\"" .. name .. "\"")
        else
            k_expected[name] = nil
        end
    end

    if #unexpected == 0 and not next(k_expected) then
        return {}, {}
    end

    local expected = {}
    for key in pairs(k_expected) do
        local name = "\"" .. tostring(key) .. "\""

        table.insert(expected, name)
    end
    
    return expected, unexpected
end

return expect_properties
