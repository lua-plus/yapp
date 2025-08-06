
local list_to_keys = require("src.table.list.to_keys")

-- From https://www.lua.org/manual/5.4/manual.html#3.1
local reserved = list_to_keys({
    "and", "break", "do", "else", "elseif", "end",
    "false", "for", "function", "goto", "if", "in",
    "local", "nil", "not", "or", "repeat", "return",
    "then", "true", "until", "while",
})

local namepat = "^[%a_][%w_]*$"

--- Check if any input is a string that is a valid lua name.
---@param input any
---@return boolean
local function is_lua_name (input)
    if type(input) ~= "string" then
        return false
    end

    if reserved[input] then
        return false
    end

    if not input:match(namepat) then
        return false
    end

    return true
end

return is_lua_name