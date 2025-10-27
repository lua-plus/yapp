
local spawn_sync = require("src.os.spawn.sync")
local has_cmd = require("src.os.sys.has_cmd")
local sep = require("src.fs.path.sep")

--- Get the OS's kernel name, if possible
---@return "windows" | "darwin" | "linux" | nil
local function get_uname ()
    if sep == "\\" then
        return "windows"
    end

    if not has_cmd("uname") then
        return nil
    end

    local uname = spawn_sync("uname")

    if uname == "Darwin" then
        return "darwin"
    elseif uname == "Linux" then
        return "linux"
    end

    return nil
end

local uname = get_uname()

return uname