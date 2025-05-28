local dirname = require("src.fs.path.dirname")
local ls = require("src.fs.ls")
local is_dir = require("src.fs.is_dir")
local parse = require("src.fs.path.parse")
local join     = require("src.fs.path.join")
local exists   = require("src.fs.exists")

--- If a string has a trailing ".init", remove it.
---@param modname string
---@return string
local function rm_trailing_init(modname)
    if modname:sub(-5) == ".init" then
        return modname:sub(1, -6)
    end

    return modname
end

-- TODO mark as 'force atomic' or similar so LuaPlus can bundle
---@param modname string
---@param modpath string
local function namespace(modname, modpath)
    -- TODO assert modname & modpath are expected values

    local modroot = rm_trailing_init(modname)

    local dir = dirname(modpath)

    local modules = {}

    for _, file in ipairs(ls(dir)) do
        local path = join(dir, file)
        file = parse(file).name

        local sub_mod = modroot .. "." .. file
        local sub_init = rm_trailing_init(sub_mod)

        -- avoid infinite recursion
        if not (sub_mod == modname or sub_init == modroot) then
            if not is_dir(path) or exists(join(path, "init.lua")) then
                modules[file] = require(sub_mod)
            end
        end
    end

    return modules
end

return namespace
