
local sep = require("src.fs.path.sep")

--- Perform text replacement on any slashes in a path, resulting in a path that
--- accurately reflects the file path while remaining OS-agnostic.
---@param path string
---@return string
local function replace(path)
    local subbed = path:gsub("[/\\]", sep)

    return subbed
end

return replace