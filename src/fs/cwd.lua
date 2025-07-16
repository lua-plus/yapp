local sep = require("src.fs.path.sep")
local is_windows = require("src.os.is_windows")

--- Append a slash to the end of a path if it isn't already there.
---@param path string
---@return string
local function terminate_sep(path)
    if path:sub(-1, -1) ~= sep then
        return path .. sep
    end

    return path
end

local has_lfs, lfs = pcall(require, "lfs")

if has_lfs then
    local cwd_lfs = function()
        return terminate_sep(lfs.currentdir())
    end

    return cwd_lfs
end

if is_windows then
    local cwd_windows = function()
        local handle, err = io.popen("cd")

        if not handle then
            error(err)
        end

        return terminate_sep(handle:read())
    end

    return cwd_windows
end


local cwd_unix = function()
    local pwd = os.getenv("PWD")

    assert(pwd and #pwd ~= 0, "No PWD")

    return terminate_sep(pwd)
end

return cwd_unix
