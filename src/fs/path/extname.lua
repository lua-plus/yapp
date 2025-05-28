
--- Get the extension name of a path
---@param path string
---@return string
local function extname (path)
    return path:match("%.[^%.]*$") or ""
end

return extname