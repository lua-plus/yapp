
---@param cmd string
local function spawn_sync (cmd)
    local handle, err = io.popen(cmd, "r")

    if not handle then
        error(err)
    end

    return handle:read("a")
end

return spawn_sync