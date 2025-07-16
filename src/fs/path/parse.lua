---@nospec

local basename = require("src.fs.path.basename")
local dirname  = require("src.fs.path.dirname")
local extname  = require("src.fs.path.extname")
local filename = require("src.fs.path.filename")

---@param path string
---@return { dir: string, base: string, name: string, ext: string }
local function parse(path)
    return {
        dir = dirname(path),
        base = basename(path),
        name = filename(path),
        ext = extname(path)
    }
end

return parse
