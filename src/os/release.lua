local is_windows = require("src.os.is_windows")
local spawn_sync = require("src.__internal.spawn_sync")
local warn       = require("src.debug.warn")

---@return string?
local function release()
    if is_windows then
        local ok, ret = pcall(spawn_sync, "ver")

        if not ok then
            warn(ret)

            return nil
        end

        return ret:match("(%S+)\n$")
    end

    -- TODO why do I not pcall here?
    return spawn_sync("uname -r")
end

return release