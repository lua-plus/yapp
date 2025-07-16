---@nospec tested in spec/math/idiv_spec.lua

---@diagnostic disable-next-line:deprecated
local load = loadstring or load
local has_idiv_op = load("return 2 // 2")

if has_idiv_op then
    return require("src.math.idiv.idiv_53")
else
    return require("src.math.idiv.idiv")
end
