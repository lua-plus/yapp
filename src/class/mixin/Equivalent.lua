local get_properties = require("src.__internal.class.get_properties")
local named_mixin = require("src.__internal.class.mixin.named_mixin")
local get_class = require("src.__internal.class.get_class")
local Verify = require("src.class.mixin.Verify")
local expect_properties = require("src.__internal.class.mixin.expect_properties")

---@class Yapp.Mixin.Equivalent : Log.BaseFunctions
local Equivalent = named_mixin("Equivalent", {})

--- Check if two values are instances or classes, and that they are equivalent.
--- This is the function used by __eq
---@generic S : Log.Class, S: Log.BaseFunctions
---@generic O : Log.Class, O: Log.BaseFunctions
---@param self S
---@param other O
---@return boolean
Equivalent.is = function(self, other)
    if type(self) ~= "table" or type(other) ~= "table" then
        return false
    end

    if rawequal(self, other) then
        return true
    end

    if not Equivalent.is_class(self, other) then
        return false
    end

    return Equivalent.is_fast(self, other)
end

--- Knowing two values are instances or classes, check if they are equivalent
---@generic S : Log.Class, S: Log.BaseFunctions
---@generic O : Log.Class, O: Log.BaseFunctions
---@param self S
---@param other O
---@return boolean
Equivalent.is_fast = function(self, other)
    local self_class = get_class(self)
    if rawequal(self, self_class) then
        return false
    end

    local other_class = get_class(other)
    if self_class ~= other_class then
        return false
    end

    return Equivalent.is_from_matching_instances(self, other)
end


local Equivalent_get_properties_cache = setmetatable({}, { __mode = "k" })
---@param class Log.Class
local function Equivalent_get_getters(class)
    local cached = Equivalent_get_properties_cache[class]
    if cached then
        return cached
    end

    local names = get_properties.names(class)
    local prop_flags = class[Equivalent]

    local getters = {}
    for _, name in ipairs(names) do
        local prop_flag = prop_flags == nil and true or prop_flags[name]

        if prop_flag == nil then
            local class_name = tostring(class)
                :gsub("^class '([^']+)' %(table: 0x%w+%)$", "%1")

            error(string.format(
                "While fetching properties for class %q: " ..
                "%q must be set to true or false.",
                class_name, name
            ), 2)
        elseif prop_flag == true then
            local getter = get_properties.getter(class, name)
            getters[getter] = true
        elseif prop_flag ~= false then
            error(string.format(
                "Equivalent: unknown property flag value %s", prop_flag
            ))
        end
    end

    Equivalent_get_properties_cache[class] = getters
    return getters
end

---@generic T : Log.Class, T: Log.BaseFunctions
---@param self T
---@param other T
---@return boolean
Equivalent.is_from_matching_instances = function(self, other)
    local self_class = get_class(self)
    if not self_class then
        return false
    end

    local getters = Equivalent_get_getters(self_class)

    for getter in pairs(getters) do
        -- TODO add 'loose' getters - same type, same function dump, etc.

        if getter(self) ~= getter(other) then
            return false
        end
    end
    return true
end

---@generic T : Log.Class
---@param self Yapp.Mixin.Equivalent
---@param other T
---@return T | nil
Equivalent.is_class = function(self, other)
    local self_class = get_class(self)
    local other_class = get_class(other)

    assert(self_class, "Self is neither a class nor instance")

    if self_class == other_class or self_class:subclassOf(other_class) then
        return self
    end

    return nil
end

Equivalent.__eq = function(self, other)
    return Equivalent.is(self, other)
end

Equivalent[Verify.verification] = function(class, properties)
    local expected, unexpected = expect_properties(class, properties)

    if #expected == 0 and #unexpected == 0 then
        return true
    end

    local err_expected =
        #expected == 1 and ("Expected equivalence property %s"):format(expected[1]) or
        #expected >= 2 and ("Expected equivalence properties %s"):format(table.concat(expected, ", ")) or
        nil

    local err_unexpected =
        #unexpected == 1 and ("Unexpected equivalence property %s"):format(unexpected[1]) or
        #unexpected >= 2 and ("Unexpected equivalence properties %s"):format(table.concat(unexpected, ", ")) or
        nil

    return false, table.concat({ err_expected, err_unexpected }, ". ")
end

return Equivalent
