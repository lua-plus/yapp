local deserialize = require("src.io.deserialize")

--- Deserialize a stringified lua value from a path. BEWARE: This function
--- performs aribtrary execution
---@generic T
---@param path string
---@param fallback T?
---@return T
local function parse (path, fallback)
    local f, err = io.open(path, "r")

    if not f then
        if fallback then
            return fallback
        end

        error(err)
    end

    local content = f:read("a")
    return deserialize(content)
end

return parse