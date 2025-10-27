
local _addrs = setmetatable({}, { __mode = "k" })
local _names = setmetatable({}, { __mode = "k" })

---@param mixin table
local function stringifier (mixin)
    return ("mixin '%s' (%s)"):format(
        _names[mixin] or "?",
        _addrs[mixin] or "?"
    )
end

--- Generate a __tostring signature that follows the format of 30log classes and
--- instances
---@param mixin table
---@param name string
local function get_stringifier (mixin, name)
    local addr = tostring(mixin)
    _addrs[mixin] = addr
    _names[mixin] = name

    return stringifier
end

return get_stringifier