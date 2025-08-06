local globals = require("src.__internal.globals")
globals.init(_G)
local base_options = require("src.io.serialize.util.options")

local crush_deep = require("src.table.crush_deep")

---@class Yapp.Io.Serialize.SerAPI
---@field ser_child fun(item: any): string Serialize an item with child indent
---@field ser fun(item: any): string Serialize an item with no indent
---@field get_indent fun(offset?: integer): string Get an indent offset from the current.

---@alias Yapp.Io.Serialize.State [
---     Yapp.Io.Serialize.Options,
---     table<any, true>,
---     integer,
---     Yapp.Io.Serialize.SerAPI,
---]

local global_names = globals.get_names()

---@param value any
---@param state Yapp.Io.Serialize.State
---@return string
local function serialize_internal(value, state)
    local options = state[1]
    local traversed = state[2]
    local depth = state[3]
    local ser_api = state[4]

    local indent = ser_api.get_indent()

    local ty = type(value)

    if ty == "table" then
        local on_dup = options.table.on_duplicate --[[ @as function ]]

        -- recursion check
        if traversed[value] then
            return indent .. on_dup(value, "recursive")
        end
        traversed[value] = true

        -- self-generating check
        local mt = getmetatable(value) or {}
        if mt.__index then
            local key = nil
            -- Retrieve the first key from pairs instead of next, because
            -- pairs may be virtual.
            for k in pairs(value) do
                key = k; break
            end

            -- Check for an identical sub-table
            local sub = value[key]
            local sub_mt = type(sub) == "table" and
                getmetatable(sub) or
                {}

            -- Check for an identical sub-sub-table
            if sub_mt == mt then
                local sub_sub = sub[key]
                local sub_sub_mt = type(sub_sub) == "table" and
                    getmetatable(sub_sub) or
                    {}

                if sub_sub_mt == sub_mt then
                    return indent .. on_dup(value, "self-generating")
                end
            end
        end
    end

    local ty_settings = options[ty]
    if not ty_settings.allowed then
        error("Cannot serialize " .. ty)
    end

    if (ty == "table" or ty == "function") and options.use_globals then
        local global_name = global_names[value]

        if global_name then
            return indent .. global_name
        end
    end

    local format = ty_settings.format
    local format_default = base_options.default[ty].format --[[ @as function ]]
    local fmt_ty = type(format)

    ---@type string
    local ret_str

    -- push depth
    state[3] = depth + 1
    if fmt_ty == "string" then
        local inner = format_default(value, ser_api, nil)

        ret_str = string.format(format, inner)
    elseif fmt_ty == "function" then
        ret_str = format(value, ser_api, format_default)
    else
        error("Unexpected format of type " .. fmt_ty)
    end
    -- pop depth
    state[3] = depth

    return indent .. ret_str
end

---@param value any
---@param options Yapp.Io.Serialize.Options | nil | boolean
---@return string
local function serialize(value, options)
    -- Compat with older versions of serialize
    if options == true then
        options = base_options.soft
    elseif options == false then
        options = nil
    end
    -- make sure we have fallback values for any setting.
    options = crush_deep(base_options.default, options)

    ---@type Yapp.Io.Serialize.State
    local state = {}

    local traversed = {}
    local depth = 0

    ---@type Yapp.Io.Serialize.SerAPI
    local ser_api = {
        ser = function(item)
            local old_depth = state[3]
            state[3] = 0

            local ret = serialize_internal(item, state)

            state[3] = old_depth
            return ret
        end,
        ser_child = function(item)
            return serialize_internal(item, state)
        end,
        get_indent = function(offset)
            local indent = options.indent --[[ @as string ]]
            local depth = state[3]

            offset = offset or 0

            return string.rep(indent, depth + offset)
        end
    }

    state[1] = options
    state[2] = traversed
    state[3] = depth
    state[4] = ser_api

    -- state = { options, traversed, depth, ser_api }

    return serialize_internal(value, state)
end

return serialize
