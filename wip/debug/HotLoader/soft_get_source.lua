
local debug_repo = require("wip.debug.HotLoader.debug_repo")

--- Get the Lua source path for a given call level
---@param level integer
---@return string|nil
local function soft_get_source(level)
    if not debug_repo.getinfo then
        return nil
    end

    local info = debug_repo.getinfo(level + 1, "S")

    local source = info.source
    if source == "=[C]" then
        return nil
    end

    return source:sub(2)
end

return soft_get_source