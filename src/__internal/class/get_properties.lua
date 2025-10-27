local class = require("lib.30log")

local get_properties = {}

--- names = list of truncated names
--- getter_names = truncated -> real
--- setter_names = truncated -> real
---@type table<LogClass, {
---     names: string[],
---     getter_names: table<string, string>,
---     setter_names: table<string, string>,
---}>
get_properties._cache = setmetatable({}, { __mode = "k" })

---@param object table | userdata
---@param key any
---@param value any
---@overload fun(object: table | userdata, key: any, value: any): nil
---@return string truncated_name
---@return string getter_name
---@return string setter_name
function get_properties._extract_property(object, key, value)
    -- we only care about string keys and function values
    if type(key) ~= "string" or type(value) ~= "function" then
        return nil
    end

    -- Make sure it's a getter, and figure out the code style
    local method_caps, underscore, field_caps, field = key:match(
        "^([gG])et(_?)([%w_])([%w_]*)"
    )

    if not (method_caps and field_caps and field) then
        return nil
    end

    -- Assert we have a setter too
    local setter_name = ("set_")
        :gsub("^s", method_caps == "G" and "S" or "s")
        :gsub("_$", underscore)
        .. field_caps .. field

    ---@type function | nil
    local setter = object[setter_name]
    if not setter or type(setter) ~= "function" then
        return nil
    end

    -- lower the first letter of the field unless the method is capitalized
    local truncated = (method_caps == "G" and
        field_caps or field_caps:lower()
    ) .. field

    return truncated, key, setter_name
end

---@param self Log.BaseFunctions | Log.Class
---@return LogClass
function get_properties._get_class(self)
    local this_class =
        class.isClass(self) and self or
        class.isInstance(self) and self.class

    if not this_class then
        error("Expected a class or instance", 2)
    end

    return this_class
end

---@param class LogClass
function get_properties._internal(class)
    local cached = get_properties._cache[class]
    if cached then
        return cached
    end

    local names = {}
    local getter_names = {}
    local setter_names = {}

    for k, v in pairs(class) do
        local truncated, getter, setter =
            get_properties._extract_property(class, k, v)

        if truncated then
            table.insert(names, truncated)

            getter_names[truncated] = getter
            setter_names[truncated] = setter
        end
    end

    local class_info = {
        names = names,
        setter_names = setter_names,
        getter_names = getter_names
    }

    get_properties._cache[class] = class_info

    return class_info
end

---@param object Log.BaseFunctions | Log.Class
---@return string[]
function get_properties.names(object)
    local class = get_properties._get_class(object)

    return get_properties._internal(class).names
end

---@param object Log.BaseFunctions | Log.Class
---@param name string
---@return function
function get_properties.getter(object, name)
    local class = get_properties._get_class(object)

    local properties = get_properties._internal(class)
    local getter_name = properties.getter_names[name]

    return object[getter_name]
end

---@param object Log.BaseFunctions | Log.Class
---@param name string
---@return function
function get_properties.setter(object, name)
    local class = get_properties._get_class(object)

    local properties = get_properties._internal(class)
    local setter_name = properties.setter_names[name]

    return object[setter_name]
end

---@param object Log.BaseFunctions | Log.Class
---@param name string
---@return any
function get_properties.get(object, name)
    local getter = get_properties.getter(object, name)

    return getter(object)
end

---@param object Log.BaseFunctions | Log.Class
---@param name string
---@param value any
function get_properties.set(object, name, value)
    local setter = get_properties.setter(object, name)

    return setter(object, value)
end

return get_properties
