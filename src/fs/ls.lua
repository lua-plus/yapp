local has_lfs, lfs = pcall(require, "lfs")

local is_windows = require("src.os.is_windows")

---@alias Yapp.Fs.Ls fun (path: string): string[]

if has_lfs then
    ---@type Yapp.Fs.Ls
    local function ls_lfs(path)
        local children = {}

        -- returns same as ls -a
        for child in lfs.dir(path) do
            -- ignore . and ..
            if child ~= "." and child ~= ".." then
                table.insert(children, child)
            end
        end

        return children
    end
    return ls_lfs
end

if is_windows then
    --- really this is dos too but dos will match windows
    ---@type Yapp.Fs.Ls
    local function ls_windows(path)
        local children = {}

        local command = string.format("dir /b %q", path)
        local handle, err = io.popen(command, "r")
        if not handle then
            error(string.format("Unable to run %q: %q", command, err))
        end

        for child in handle:lines("l") do
            table.insert(children, child)
        end

        return children
    end
    return ls_windows
end

---@type Yapp.Fs.Ls
local function ls_unix(path)
    local children = {}

    local command = string.format("ls -A %q", path)
    local handle, err = io.popen(command, "r")
    if not handle then
        error(string.format("Unable to run %q: %q", command, err))
    end

    for child in handle:lines("l") do
        table.insert(children, child)
    end

    return children
end

return ls_unix