---@nospec
--- TODO is there a way to test this?

local has_lfs, lfs = pcall(require, "lfs")
local uname = require("src.os.sys.uname")

---@alias Yapp.Fs.Mkdir fun (path: string): nil

if has_lfs then
    ---@type Yapp.Fs.Mkdir
    local function mkdir_lfs(path)
        lfs.mkdir(path)
    end
    return mkdir_lfs
end

if uname == nil then
    return nil
end

if uname == "windows" then
    ---@type Yapp.Fs.Mkdir
    local function mkdir_windows(path)
        os.execute(string.format("mkdir %q", path))
    end
    return mkdir_windows
end


---@type Yapp.Fs.Mkdir
local function mkdir_unix(path)
    os.execute(string.format("mkdir %q", path))
end

return mkdir_unix
