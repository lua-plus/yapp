
local get_stringifier = require("src.__internal.class.mixin.get_stringifer")
local mt_mixin = require("src.__internal.class.mixin.mt_mixin")

---@generic T : table
---@param name string
---@param mixin T
---@return T
local function named_mixin (name, mixin)
    return mt_mixin(mixin, {
        __tostring = get_stringifier(mixin, name)
    })
end

return named_mixin