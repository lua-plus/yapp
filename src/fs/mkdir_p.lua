
local dirname = require("src.fs.path.dirname")
local split = require("src.string.split")
local sep = require("src.fs.path.sep")
local reduce = require("src.table.list.reduce")
local join = require("src.fs.path.join")
local exists = require("src.fs.exists")
local mkdir = require("src.fs.mkdir")
local is_dir = require("src.fs.is_dir")

---@param path string
local function mkdir_p (path)
    local dir = dirname(path)
    
    local slices = split(dir, sep)
    
    reduce(slices, function (previous, slice)
        local path = join(previous, slice)

        if not exists(path) then
            mkdir(path)
        elseif not is_dir (path) then
            error(string.format("Path %q is a file - directory expected!", path))
        end

        return path
    end, dir:sub(1,1) == sep and sep or "")
end

return mkdir_p