
_G.print = require("src.debug.print")

local unpack = require("src.table.unpack")
local map = require("src.table.map")

local replacements = {
    timestamp = function () return os.time() end,
    message = function () return "Hello World!" end
}

local replacements_index = {}
for name, rep_fn in pairs(replacements) do
    table.insert(replacements_index, { name, rep_fn })
end

-- String formatting toy example
local fmt = "[ERROR] {timestamp} {message} {timestamp}"

local indices = {}
local new_fmt = fmt:gsub("%{([^}]+)%}", function (label)
    local idx = -1
    for i, info in ipairs(replacements_index) do
        local name = info[1]

        if name == label then
            idx = i
            break
        end
    end

    if idx == -1 then
        error("No label " .. label)
    end

    table.insert(indices, idx)

    return "%s"
end)
print(indices, new_fmt)

print(new_fmt:format(unpack(map(indices, function (index)
    local info = replacements_index[index]

    return info[2]()
end))))