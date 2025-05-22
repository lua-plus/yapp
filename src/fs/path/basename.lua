
---@param path string
local function basename (path)
    local filename = path:match("[/\\].-$") or path

    local basename = filename:match("^(.-)%.[^%.]*$") or filename

    return basename
end

return basename