
--- Load a serialized value. BEWARE: This function performs arbitrary execution. 
---@param str string
---@return any
local function deserialize (str)
    local get_chunk, err = load("return " .. str, "deserialized input")

    if not get_chunk then
        error(err)
    end

    return get_chunk()
end

return deserialize