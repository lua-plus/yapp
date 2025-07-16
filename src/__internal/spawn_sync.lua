
---@param cmd string
---@return string output
local function spawn_sync (cmd)
    local handle, err = io.popen(cmd, "r")

    if not handle then
        error(err)
    end

    -- remove trailing newline
    return handle:read("a"):sub(1,-2)
end

return spawn_sync