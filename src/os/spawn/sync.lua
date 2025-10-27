
---@param cmd string
---@return string output
local function spawn_sync (cmd)
    local handle, err = io.popen(cmd, "r")

    if not handle then
        error(err)
    end

    -- remove trailing newline
    local ret = handle:read("a"):sub(1,-2)
    local _, _, code = handle:close()

    if code == 0 then
        return ret
    else
        error(ret)
    end
end

return spawn_sync