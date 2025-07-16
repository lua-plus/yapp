---@nospec

local cwd = require("src.fs.cwd")
local sep = require("src.fs.path.sep")
local join = require("src.fs.path.join")

---@param ... string
local function resolve(...)
    local p = join(...)

    if p:sub(1, 1) ~= sep then
        p = cwd() .. p
    end

    -- NodeJS lets us do this. Kinda neat, so I stole it.
    p = p:gsub("[/\\]", sep)

    -- join() replaces path/../ etc.
    return join(p)
end

return resolve
