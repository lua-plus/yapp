
local class = require("lib.30log")

---@param value Log.Class | Log.BaseFunctions
---@return Log.Class | nil
local function get_class(value)
    return
        class.isClass(value) and value or
        class.isInstance(value) and value.class or 
        nil
end

return get_class