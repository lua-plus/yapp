
local basename = require("src.fs.path.basename")

--- Get the actual filename of the path, without extension
---@param path string
---@return string
local function filename (path)
    local base = basename(path)
    local name = base:match("^(.-)%.[^%.]*$") or base

    return name
end

return filename