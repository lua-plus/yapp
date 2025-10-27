local spawn_sync = require("src.os.spawn.sync")
local is_windows = require("src.__internal.os.is_windows")

---@param exe string
---@return boolean
local function has_cmd(exe)
    --[[
    Microsoft does this cool thing where they hate you for trying to develop
    software that uses shell scripts. `where` performs almost exactly the
    same as `which`, but has different formats.
    ]]
    local which = is_windows and "where" or "which"

    local cmd = string.format("%s %s", which, exe)
    local ok = pcall(spawn_sync, cmd)

    return ok
end

return has_cmd
