local ok, get_source    = pcall(require, "src.debug.fn.get_source")
local get_table_entries = require("src.io.serialize.util.get_table_entries")


local get_source = (function()
    if ok then
        return get_source
    end
end)()


local options   = {}

---@alias Yapp.Io.Serialize.Options {
---     indent?: string,
---     max_depth?: integer,
---     use_globals?: boolean,
---     nil?: {
---         allowed?: boolean,
---         format?: (fun(n: nil, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
---     number?: {
---         allowed?: boolean,
---         format?: (fun(num: number, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
---     string?: {
---         allowed?: boolean,
---         format?: (fun(str: string, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
---     boolean?: {
---         allowed?: boolean,
---         format?: (fun(bool: boolean, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
---     table?: {
---         allowed?: boolean,
---         format?: (fun(t: table, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---         on_duplicate?: (fun(dup: table, kind: "recursive"|"self-generating"): string),
---     },
---     function?: {
---         allowed?: boolean,
---         format?: (fun(fn: function, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
---     thread?: {
---         allowed?: boolean,
---         format?: (fun(co: thread, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
---     userdata?: {
---         allowed?: boolean,
---         format?: (fun(ud: userdata, ser_api: Yapp.Io.Serialize.SerAPI, default: (fun(value, api))): string) | string,
---     },
--- }

---@type Yapp.Io.Serialize.Options
options.default = {
    indent = "\t",
    use_globals = true,
    ["nil"] = {
        allowed = true,
        format = tostring --[[ @as function ]]
    },
    ["number"] = {
        allowed = true,
        format = tostring --[[ @as function ]]
    },
    ["string"] = {
        allowed = true,
        format = function(str)
            return string.format("%q", str)
        end
    },
    ["boolean"] = {
        allowed = true,
        format = tostring --[[ @as function ]]
    },
    ["table"] = {
        allowed = true,
        format = function(t, api)
            local entries = get_table_entries(t, api.ser)

            if #entries == 0 then
                return "{}"
            end

            local child_indent = api.get_indent()

            -- TODO this feels hacky.
            for i, entry in ipairs (entries) do
                entries[i] = entry:gsub("\n", "\n" .. child_indent)
            end

            local s_entries = table.concat(entries, ",\n" .. child_indent)
            local end_indent = api.get_indent(-1)

            return "{\n" .. child_indent .. s_entries .. "\n" .. end_indent .. "}"
        end,
        on_duplicate = function(_, kind)
            if kind == "recursive" then
                error("Cannot serialize recursive values", 2)
            else
                error("Cannot serialize deep self-generating tables", 2)
            end
        end
    },
    ["function"] = {
        allowed = true,
        format = function(fn)
            local name = "function"

            if get_source then
                name = "function " .. get_source(fn)
            end

            return string.format(
                "--[[ (Serialized %s) ]] load(%q)()",
                name,
                string.dump(fn)
            )
        end
    },
    ["thread"] = {
        allowed = false
    },
    ["userdata"] = {
        allowed = false
    },
}

---@type Yapp.Io.Serialize.Options
options.soft    = {
    ["table"] = {
        format = function(t, api, default)
            local mt = getmetatable(t) or {}

            if mt.__tostring then
                return tostring(t)
            else
                return options.default["table"].format(t, api, default)
            end
        end,
        on_duplicate = function(_, kind)
            if kind == "recursive" then
                return "(recursive table)"
            else
                return "(deep self-generating table)"
            end
        end
    },
    ["function"] = {
        format = function(fn)
            if get_source then
                return "[function " .. get_source(fn) .. "]"
            else
                return "[function]"
            end
        end
    }
}


return options
