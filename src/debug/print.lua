local serialize = require("src.io.serialize")
local chalk = require("src.term.chalk")
local get_table_entries = require("src.__internal.io.serialize.get_table_entries")

local get_source = (function()
    local ok, get_source = pcall(require, "src.debug.fn.get_source")
    if ok then
        return get_source
    end
end)()

-- TODO FIXME fails to print debug.getregistry()

-- undefined -> gray
-- null -> white bold
-- number -> orangeish yellow
-- string -> as-is (but green if enclosed in object/array)
-- boolean -> orangish yellow

-- object -> key: none
-- function -> teal

-- TODO dynamically scale this against current line length
local max_t_width = 80

---@type Yapp.Io.Serialize.Options
local ser_options = {
    ["nil"] = {
        format = chalk.gray("%s")
    },
    ["number"] = {
        format = chalk.yellow("%s")
    },
    ["string"] = {
        format = chalk.green("%s")
    },
    ["boolean"] = {
        format = chalk.yellow("%s")
    },
    ["table"] = {
        format = function(t, api)
            local mt = getmetatable(t) or {}
            if mt.__tostring then
                return tostring(t)
            end

            local entries = get_table_entries(t, api.ser)

            if #entries == 0 then
                return "{}"
            end

            local single_line = "{ " .. table.concat(entries, ", ") .. " }"
            if #chalk.strip(single_line) <= max_t_width then
                return single_line
            end

            local child_indent = api.get_indent()

            -- TODO this feels hacky.
            for i, entry in ipairs(entries) do
                entries[i] = entry:gsub("\n", "\n" .. child_indent)
            end

            local s_entries = table.concat(entries, ",\n" .. child_indent)
            local end_indent = api.get_indent(-1)

            return "{\n" .. child_indent .. s_entries .. "\n" .. end_indent .. "}"
        end,
        on_duplicate = function(_, kind)
            if kind == "recursive" then
                return chalk.red("[recursive table]")
            else
                return chalk.red("[self-generating table]")
            end
        end
    },
    ["function"] = {
        format = function(fn)
            local ret = "[function"
            if get_source then
                local source = get_source(fn)

                -- TODO this feels hacky lol
                if source == "(C function)" then
                    return chalk.cyan("[C function]")
                end

                ret = ret .. " " .. source
            end
            ret = ret .. "]"

            return chalk.cyan(ret)
        end
    },
    ["thread"] = {
        allowed = true,
        format = function(co)
            local addr = tostring(co):match("0x[%dabcdef]+")

            return chalk.cyan("[thread " .. addr .. "]")
        end,
    },
    ["userdata"] = {
        allowed = true,
        format = function(ud)
            local mt = getmetatable(ud) or {}
            if mt.__tostring then
                return tostring(ud)
            end

            local name = mt.__name or "userdata"
            local addr = tostring(ud):match("0x[%dabcdef]+")
            return chalk.cyan("[" .. name, addr .. "]")
        end,
    }
}

--- Print an output more similar to Node.js
---@param ... any
local function print(...)
    local argv = select("#", ...)
    local args = { ... }

    local stdout = io.stdout

    for i = 1, argv do
        local arg = args[i]

        local str = ""
        if type(arg) == "string" then
            str = arg
        else
            str = serialize(arg, ser_options)
        end
        stdout:write(str)

        if i ~= argv then
            stdout:write(" ")
        end
    end
    stdout:write("\n")
end

return print
