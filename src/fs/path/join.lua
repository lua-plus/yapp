local sep = require("src.fs.path.sep")
local table_pack = require("src.table.pack")

---@param ... string
local function join(...)
    local elements = table_pack(...)

    local ret = {}

    for i = 1, #elements do
        local item = elements[i]

        if item then
            local is_first = i == 1

            -- Remove starts with slash
            if item:sub(1, 1) == sep and not is_first then
                item = item:sub(2)
            end

            -- Remove starts with ./
            if item:sub(1, 2) == ("." .. sep) and not is_first then
                item = item:sub(3)
            end

            if item:sub(-1) == sep then
                item = item:sub(1, -2)
            end

            -- Not stripping whitespace here is important - "/" -> "" -> {"", ...paths} -> "/...paths"
            table.insert(ret, item)
        end
    end

    local joined = table.concat(ret, sep)
        -- remove /./
        :gsub("[/\\]%.[/\\]", sep)
        -- remove /<path>/../
        :gsub("[/\\][^/\\]+[/\\]%.%.[/\\]", sep)

    return joined
end

return join
