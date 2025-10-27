
--- Set the metatable of a mixin gently
---@generic T : table
---@param mixin T
---@param metatable metatable
---@return T
local function mt_mixin (mixin, metatable)
    local mt = getmetatable(mixin) or {}
    for k, v in pairs(metatable) do
        if mt[k] then
            error(("Mixin already has metatable event %s"):format(k))
        end
        mt[k] = v
    end

    return setmetatable(mixin, mt)
end

return mt_mixin