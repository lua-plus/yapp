local uname      = require("src.os.sys.uname")
local spawn_sync = require("src.os.spawn.sync")
local warn       = require("src.debug.warn")

--- Get the release number of the operating system
---@return string?
local function release()
    if uname == "windows" then
        local ok, ret = pcall(spawn_sync, "ver")

        if not ok then
            warn(ret)

            return nil
        end

        return ret:match("(%S+)\n$")
    end

    if uname == nil then
        return nil
    end

    -- TODO why do I not pcall here?
    return spawn_sync("uname -r")
end

return release
