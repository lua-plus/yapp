local serialize = require("src.io.serialize")

---@param val any
---@param path string
local function dump(val, path)
    local content = serialize(val)

    local f, err = io.open(path, "w")
    if not f then
        error(err)
    end

    f:write(content)
    f:flush()
    f:close()
end

return dump
