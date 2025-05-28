
---@param path string
local function basename (path)
    return path:match("[/\\].-$") or path
end

return basename