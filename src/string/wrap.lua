---@param value string
---@param mode "on"|"off"|"overflow"|nil
---@param pos { [1|2|3|4]: integer } x, y, width, height
---@param overflow_str string?
local function wrap(value, mode, pos, overflow_str)
    mode = mode or "on"
    overflow_str = overflow_str or "..."

    local x, y, width, height = table.unpack(pos)

    local lines = {}
    local buffer = value
    while #buffer ~= 0 and #lines <= height do
        -- remove preceding x value
        buffer = buffer:sub(x)

        -- remove leading whitespace
        local _, ws_end = buffer:find("^%s+")
        if ws_end then
            buffer = buffer:sub(ws_end + 1)
        end

        ---@type string
        local sub = buffer:match("^[^\n\r]+")

        if not sub then
            table.insert(lines, "")
            buffer = buffer:sub(1)
        elseif #sub <= width then
            table.insert(lines, sub)
            buffer = buffer:sub(#sub + 1)
        elseif mode == "on" then
            -- TODO how to handle x ~= 1?

            local s_end = sub:sub(1, width)
            -- find the whitespace closest to the end of this line
            local ws = s_end:find("%s.-$")
            if ws then
                -- wrap to that whitespace
                sub = sub:sub(1, ws)
                table.insert(lines, sub)
                buffer = buffer:sub(ws + 1)
            else
                -- or just hyphenate
                sub = s_end:sub(1, -2) .. "-"
                table.insert(lines, sub)
                buffer = buffer:sub(width)
            end
        elseif mode == "off" then
            sub = sub:sub(1, width)
            table.insert(lines, sub)
            buffer = buffer:match("^.-[\n\r]")
        elseif mode == "overflow" then
            sub = sub:sub(1, width - #overflow_str)
            table.insert(lines, sub .. overflow_str)
            buffer = buffer:match("^.-[\n\r]")
        end
        
        -- remove a line if it is leading
        if y > 1 then
            table.remove(lines)
            y = y - 1
        end

        buffer = buffer or ""
    end

    return table.concat(lines, "\n")
end

return wrap