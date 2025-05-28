
local basename = require("src.fs.path.basename")
local dirname  = require("src.fs.path.dirname")
local extname  = require("src.fs.path.extname")

---@param path string
---@return { dir: string, base: string, name: string, ext: string }
local function parse(path)
    local base = basename(path)
    local name = base:match("^(.-)%.[^%.]*$") or base

    return {
        dir = dirname(path),
        base = base,
        name = name,
        ext = extname(path)
    }
end

return parse
